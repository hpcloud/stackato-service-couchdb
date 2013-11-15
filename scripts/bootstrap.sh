#!/usr/bin/env bash

cd $(dirname $0)

echo "Please enter cloud controller api url (api.stackato.local): "
read CCURL

# Stop kato and supervisord for reconfiguration
kato stop
stop-supervisord

# Move couchdb to the services folder and update gems
if [ ! -d /s/vcap/services/couchdb ]; then
  cd ../../
  mv stackato-couchdb /s/vcap/services/couchdb
fi
cd /s/vcap/services/couchdb && bundle install 

# Copy the stackato configuration files to supervisord
cp /s/vcap/services/couchdb/stackato-conf/couchdb_* /s/etc/supervisord.conf.d/

# Install to kato
cat /s/vcap/services/couchdb/stackato-conf/processes-snippet.yml >> /s/etc/kato/processes.yml
cat /s/vcap/services/couchdb/stackato-conf/roles-snippet.yml >> /s/etc/kato/roles.yml

# Restart supervisord
start-supervisord

# Set cc url in config
echo "cloud_controller_uri: $CCURL" >> /s/vcap/services/couchdb/config/couchdb_gateway.yml

# Add the authentication token to the cloud controller and set it in config
SERVICE_TOKEN=`date +%s | sha256sum | base64 | head -c 10`
kato config set cloud_controller builtin_services/couchdb/token "$SERVICE_TOKEN"
echo "token: $SERVICE_TOKEN" >> /s/vcap/services/couchdb/config/couchdb_gateway.yml

# Set couchdb_password / couchdb_hostname in config
COUCHDB_PASSWORD=`date +%s | sha256sum | base64 | head -c 16`
COUCHDB_HOSTNAME=localhost
COUCHDB_PORT=5984
echo "couchdb_password: $COUCHDB_PASSWORD" >> /s/vcap/services/couchdb/config/couchdb_node.yml
echo "couchdb_hostname: $COUCHDB_HOSTNAME" >> /s/vcap/services/couchdb/config/couchdb_node.yml
echo "port: $COUCHDB_PORT" >> /s/vcap/services/couchdb/config/couchdb_node.yml

# set kato config
cat /s/vcap/services/couchdb/config/couchdb_gateway.yml | kato config set couchdb_gateway / --yaml
cat /s/vcap/services/couchdb/config/couchdb_node.yml | kato config set couchdb_node / --yaml

# setup first couchdb admin
curl -X PUT http://$COUCHDB_HOSTNAME:$COUCHDB_PORT/_config/admins/admin -d'"'$COUCHDB_PASSWORD'"'

# Add the role and restart kato
kato role add couchdb
kato start

echo Success!
