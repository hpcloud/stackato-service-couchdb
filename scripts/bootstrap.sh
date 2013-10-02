#!/usr/bin/env bash

# Stop kato and supervisord for reconfiguration
kato stop
stop-supervisord

# Copy couchdb to the services folder and update gems
cp -R /home/stackato/stackato-couchdb /s/vcap/services/couchdb
cd /s/vcap/services/couchdb && bundle install 

# Copy the stackato configuration files to supervisord
cp /s/vcap/services/couchdb/stackato-conf/couchdb_* /s/etc/supervisord.conf.d/

# Install to kato
cat /s/vcap/services/couchdb/stackatocouchdb-conf/processes-snippet.yml >> /s/etc/kato/processes.yml
cat /s/vcap/services/couchdb/stackato-conf/roles-snippet.yml >> /s/etc/kato/roles.yml

# Restart supervisord
start-supervisord

# set kato config
cat /s/vcap/services/couchdb/config/couchdb_gateway.yml | kato config set couchdb_gateway / --yaml
cat /s/vcap/services/couchdb/config/couchdb_node.yml | kato config set couchdb_node / --yaml

# Add the authentication token to the cloud controller
kato config set cloud_controller builtin_services/couchdb/token "0xdeadbeef"

# Add the role and restart kato
kato role add couchdb
kato start
