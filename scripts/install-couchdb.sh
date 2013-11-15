#!/usr/bin/env bash

COUCHDB_VERSION=1.5.0
COUCHDB_ROOT=/opt/couchdb-$COUCHDB_VERSION
RESOURCES_ROOT=../resources

# make sure we are in this directory
cd $(dirname $0)

# update repositories to latest
apt-get update

# install curl in case it's not installed on the system
apt-get install -y curl

# install the libraries which couchdb needs
apt-get install -y build-essential erlang-base-hipe erlang-dev erlang-manpages erlang-eunit erlang-nox libicu-dev libmozjs-dev libcurl4-openssl-dev

# download couchdb source
curl http://apache.mirror.vexxhost.com/couchdb/source/$COUCHDB_VERSION/apache-couchdb-$COUCHDB_VERSION.tar.gz | tar xzvf -

pushd apache-couchdb-$COUCHDB_VERSION
    # install couchdb in its default location
    ./configure --prefix=$COUCHDB_ROOT && make && make install
popd

# give the stackato user proper RW perms
chown -R stackato:stackato $COUCHDB_ROOT

# installation cleanup
rm -rf apache-couchdb-$COUCHDB_VERSION

# set CouchDB defaults.
COUCHDB_HOSTNAME=`ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'`
sed -i.bak s/"bind_address = 127.0.0.1"/"bind_address = $COUCHDB_HOSTNAME"/g $RESOURCES_ROOT/default.ini
rm $COUCHDB_ROOT/etc/couchdb/default.ini
cp $RESOURCES_ROOT/default.ini $COUCHDB_ROOT/etc/couchdb/

# upstart config
cat << EOF > /etc/init/couchdb.conf
# couchdb upstart

start on runlevel [2345]
stop on runlevel [!2345]

script
    exec su stackato /opt/couchdb-$COUCHDB_VERSION/bin/couchdb
end script

respawn
respawn limit 10 5
EOF

# start couchdb
start couchdb
