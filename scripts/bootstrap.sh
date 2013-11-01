#!/bin/bash

# Stop kato and supervisord for reconfiguration
kato stop
stop-supervisord

# Copy couchdb to the services folder and update gems
cp -R /home/stackato/stackato-couchdb /s/vcap/services/couchdb
cd /s/vcap/services/couchdb && bundle install 
rm -rf /home/stackato/stackato-couchdb

# Copy the stackato configuration files to supervisord
cp /s/vcap/services/couchdb/stackato-conf/couchdb_* /s/etc/supervisord.conf.d/

# Install to kato
cat /s/vcap/services/couchdb/stackato-conf/processes-snippet.yml >> /s/etc/kato/processes.yml
cat /s/vcap/services/couchdb/stackato-conf/roles-snippet.yml >> /s/etc/kato/roles.yml

# Restart supervisord
start-supervisord

# Add the authentication token to the cloud controller
SERVICE_TOKEN=`date +%s | sha256sum | base64 | head -c 10`
kato config set cloud_controller builtin_services/couchdb/token "$SERVICE_TOKEN"
echo "token: $SERVICE_TOKEN" >> /s/vcap/services/couchdb/config/couchdb_gateway.yml

# Set cc url
echo "Please enter cloud controller api url (api.stackato.local): "
read CCURL
echo "cloud_controller_uri: $CCURL" >> /s/vcap/services/couchdb/config/couchdb_gateway.yml

# set kato config
cat /s/vcap/services/couchdb/config/couchdb_gateway.yml | kato config set couchdb_gateway / --yaml
cat /s/vcap/services/couchdb/config/couchdb_node.yml | kato config set couchdb_node / --yaml

# Add the role and restart kato
kato role add couchdb
kato start

# setup first couchdb user
COUCHDB_PASSWORD=`date +%s | sha256sum | base64 | head -c 16`
COUCHDB_HOST=localhost:5984

curl -X PUT http://localhost:5984/_config/admins/admin -d'"'$COUCHDB_PASSWORD'"'
echo "couchdb_password: $COUCHDB_PASSWORD" >> /s/vcap/services/couchdb/config/couchdb_node.yml
echo "couchdb_host: $COUCHDB_HOST" >> /s/vcap/services/couchdb/config/couchdb_node.yml

echo Success!
