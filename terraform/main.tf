# Creating a resource group
module "carshub_rg" {
  source   = "./modules/resource_groups"
  name     = "carshub_rg"
  location = var.location
}

# Key Vault for storing secrets
module "carshub_key_vault" {
  source = "./modules/key_vault"
  key_permissions = [
    "Create",
    "Get"
  ]
  secret_permissions = [
    "Set",
    "Get",
    "Delete",
    "Purge",
    "Recover"
  ]
  location                   = var.location
  rg                         = module.carshub_rg.name
  soft_delete_retention_days = 7
  sku_name                   = "premium"
  vault_name                 = "carshub"
  secrets = [
    {
      name  = "carshub-db-password"
      value = "Mohitdixit12345!"
    }
  ]
}

# Creating carshub database ( MySQL )
module "carshub_db" {
  source         = "./modules/database"
  admin_password = module.carshub_key_vault.secrets[0].value
  admin_username = "mohit"
  charset        = "utf8"
  db_name        = "carshub"
  server_name    = "carshub"
  location       = var.location
  rg             = module.carshub_rg.name
  collation      = "utf8_unicode_ci"
  sku            = "B_Standard_B1s"
}

# CarsHub virtual network
module "carshub_vnet" {
  source               = "./modules/vnet"
  rg                   = module.carshub_rg.name
  location             = var.location
  virtual_network_name = var.virtual_network_name
  vnet_address_space   = ["10.0.0.0/16"]
  network_security_groups = [
    {
      name = var.network_security_group_name
      rules = [
        {
          name                       = "web"
          priority                   = 1008
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "10.0.1.0/24"
        }
      ]
    }
  ]
  subnets = [
    {
      name             = var.subnet_name
      address_prefixes = ["10.0.1.0/24"]
    }
  ]
  # Associate the Network Security Group to the subnet
  nsg_subnet_associations = [
    {
      subnet_id                 = module.carshub_vnet.subnets[0].id
      network_security_group_id = module.carshub_vnet.network_security_groups[0].id
    }
  ]
}

# Creating a VMSS
module "vmss_frontend" {
  source                          = "./modules/vmss"
  vm_count                        = 2
  location                        = var.location
  rg                              = module.carshub_rg.name
  virtual_machine_name            = "vmss-frontend"
  size                            = var.virtual_machine_size
  admin_username                  = var.username
  network_interface_name          = "vmss-frontend-nic"
  admin_password                  = var.password
  disable_password_authentication = false
  os_disk = [
    {
      name                 = "frontend-disk"
      caching              = "ReadWrite"
      storage_account_type = var.redundancy_type
    }
  ]
  source_image_reference = [
    {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }
  ]
  network_interface_subnet       = module.carshub_vnet.subnets[0].id
  backend_address_pool_id        = module.lb_frontend.backend_address_pool_id
  extension_name                 = "Nginx"
  extension_publisher            = "Microsoft.Azure.Extensions"
  extension_type                 = "CustomScript"
  extension_type_handler_version = "2.0"
  extension_settings = jsonencode({
    "commandToExecute" : <<-EOT
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get upgrade -y
    # Installing Nginx
    sudo apt-get install -y nginx
    # Installing Node.js
    curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
    sudo bash nodesource_setup.sh
    sudo apt install nodejs -y
    # Installing PM2
    sudo npm i -g pm2

    cd /home/ubuntu
    mkdir nodeapp
    # Checking out from Version Control
    git clone https://github.com/mmdcloud/carshub-gcp-managed-instance-groups
    cd carshub-gcp-managed-instance-groups/frontend
    cp -r . /home/ubuntu/nodeapp/
    cd /home/ubuntu/nodeapp/
    # Setting up env variables
    cat > .env <<EOL
    BASE_URL=${module.lb_backend.address}
    CDN_URL=
    EOL
    # Copying Nginx config
    cp scripts/default /etc/nginx/sites-available/
    # Installing dependencies
    sudo npm i

    # Building the project
    sudo npm run build
    # Starting PM2 app
    pm2 start ecosystem.config.js
    sudo service nginx restart
  EOT
  })
}

# Creating a VMSS
module "vmss_backend" {
  source                          = "./modules/vmss"
  vm_count                        = 2
  location                        = var.location
  rg                              = module.carshub_rg.name
  virtual_machine_name            = "vmss-backend"
  size                            = var.virtual_machine_size
  admin_username                  = var.username
  network_interface_name          = "vmss-backend-nic"
  admin_password                  = var.password
  disable_password_authentication = false
  os_disk = [
    {
      name                 = "backend-disk"
      caching              = "ReadWrite"
      storage_account_type = var.redundancy_type
    }
  ]
  source_image_reference = [
    {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }
  ]
  network_interface_subnet       = module.carshub_vnet.subnets[0].id
  backend_address_pool_id        = module.lb_backend.backend_address_pool_id
  extension_name                 = "Nginx"
  extension_publisher            = "Microsoft.Azure.Extensions"
  extension_type                 = "CustomScript"
  extension_type_handler_version = "2.0"
  extension_settings = jsonencode({
    "commandToExecute" : <<-EOT
    #! /bin/bash
    apt-get update -y
    apt-get upgrade -y
    # Installing Nginx
    apt-get install -y nginx
    # Installing Node.js
    curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
    bash nodesource_setup.sh
    apt install nodejs -y
    # Installing PM2
    npm i -g pm2
    # Installing Nest CLI
    npm install -g @nestjs/cli
    mkdir nodeapp
    # Checking out from Version Control
    git clone https://github.com/mmdcloud/carshub-gcp-managed-instance-groups
    cd carshub-gcp-managed-instance-groups/backend/api
    cp -r . ../nodeapp/
    cd ../nodeapp/
    # Copying Nginx config
    cp scripts/default /etc/nginx/sites-available/
    # Installing dependencies
    npm i

    cat > .env <<EOL
    DB_PATH=${module.carshub_db.fqdn}
    UN=mohit
    CREDS=${module.carshub_key_vault.secrets[0].value}
    EOL
    # Building the project
    npm run build
    # Starting PM2 app
    pm2 start dist/main.js
    service nginx restart
  EOT
  })
}

# Load balancer configuration
module "lb_frontend" {
  source                        = "./modules/lb"
  load_balancer_name            = "lb-frontend"
  rg                            = module.carshub_rg.name
  location                      = var.location
  sku                           = "Standard"
  backend_address_pool_name     = "lb-front-pool"
  public_ip_name                = "lb-front-public-ip"
  public_ip_sku                 = "Standard"
  public_ip_allocation_method   = "Static"
  probe_name                    = "lb-front-probe"
  probe_port                    = 3000
  outbound_rule_name            = "lb-front-outbound"
  outbound_rule_protocol        = "Tcp"
  lb_rule_name                  = "lb-front-rule"
  lb_rule_protocol              = "Tcp"
  lb_rule_frontend_port         = 80
  lb_rule_backend_port          = 3000
  lb_rule_disable_outbound_snat = true
}

# Load balancer configuration
module "lb_backend" {
  source                        = "./modules/lb"
  load_balancer_name            = "lb-backend"
  rg                            = module.carshub_rg.name
  location                      = var.location
  sku                           = "Standard"
  backend_address_pool_name     = "lb-back-pool"
  public_ip_name                = "lb-back-public-ip"
  public_ip_sku                 = "Standard"
  public_ip_allocation_method   = "Static"
  probe_name                    = "lb-back-probe"
  probe_port                    = 80
  outbound_rule_name            = "lb-back-outbound"
  outbound_rule_protocol        = "Tcp"
  lb_rule_name                  = "lb-back-rule"
  lb_rule_protocol              = "Tcp"
  lb_rule_frontend_port         = 80
  lb_rule_backend_port          = 80
  lb_rule_disable_outbound_snat = true
}

# Storage
module "carshub_storage" {
  source                   = "./modules/storage"
  name                     = "carshubstorage"
  rg                       = module.carshub_rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  containers = [
    {
      name                  = "media"
      container_access_type = "private"
    }
  ]
}

# App Service Plan
module "carshub_app_service_plan" {
  source   = "./modules/app_service_plan"
  name     = "carshub-app-service-plan"
  location = var.location
  rg       = module.carshub_rg.name
  sku      = "Y1"
  os_type  = "Linux"
}

# Function app for updating storage metadata
# module "carshub_media_update_function" {
#   source                     = "./modules/function_app"
#   name                       = "carsub-media-update"
#   service_plan_id            = module.carshub_app_service_plan.service_plan_id
#   storage_account_name       = module.carshub_storage.storage_account_name
#   storage_account_access_key = module.carshub_storage.storage_account_access_key
#   location                   = var.location
#   rg                         = module.carshub_rg.name
# }

# # Deploying function app to Azure
# resource "null_resource" "deploy_media_update_function" {
#   provisioner "local-exec" {
#     command = "bash ../../frontend/artifact_push.sh https://${module.carshub_backend_app.url}"
#   }
#   depends_on = [module.carshub_container_registry]
# }
