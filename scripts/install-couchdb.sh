#!//usr/bin/env bash

COUCHDB_VERSION=1.5.0

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
    ./configure && make && make install
popd

# installation cleanup
rm -rf apache-couchdb-$COUCHDB_VERSION

# start couchdb
service start couchdb
