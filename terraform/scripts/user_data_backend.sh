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
git clone https://github.com/mmdcloud/carshub-azure-vmss
cd carshub-azure-vmss/src/backend/api
cp -r . ../nodeapp/
cd ../nodeapp/
# Copying Nginx config
cp scripts/default /etc/nginx/sites-available/
# Installing dependencies
npm i

cat > .env <<EOL
DB_PATH=$1
UN=mohit
CREDS=$2
EOL
# Building the project
npm run build
# Starting PM2 app
pm2 start dist/main.js
service nginx restart