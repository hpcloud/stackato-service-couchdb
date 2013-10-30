#!/bin/bash

# ===== download and install couchdb ===== #
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 74EE6429
echo "deb http://packages.cloudant.com/ubuntu `lsb_release -cs` main" | sudo tee /etc/apt/sources.list.d/cloudant.list
sudo apt-get update
sudo apt-get install bigcouch -y

sudo cp -f bigcouch_default_config.args /opt/bigcouch/etc/vm.args

# ===== test =====
curl -X GET http://localhost:5984
{"couchdb":"Welcome","version":"1.1.1","bigcouch":"0.4.2"}