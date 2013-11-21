CouchDB Service for Stackato
=========================

This CouchDB Service for Stackato is under active development. It is based partly on the Echo Service sample code.

This sample is based on [cloudfoundry/vcap-services/echo](https://github.com/cloudfoundry/vcap-services/tree/master/echo)
with some additional configuration (e.g for `kato` and `supervisord`)
and other minor differences. The instructions here are for [Stackato
2.10.6](http://www.activestate.com/stackato/get_stackato).

## Copying/Cloning the Service to Stackato

Log in to the Stackato VM (micro cloud or service node) as the
'stackato' user and clone this repository directly into a
vcap/services/couchdb directory:

    $ git clone https://github.com/shsu/stackato-couchdb.git /s/vcap/services/couchdb

**Alternatively**, you can scp a local checkout of stackato-couchdb to Stackato using SCP.

## Customize CouchDB

You can customize your couchdb installation by editing `resources/default.ini` before running the install script.

## Installation

Execute scripts/install_couchdb.sh and scripts/bootstrap.sh:

    $ cd /scripts
    $ sudo ./install-couchdb.sh
    $ ./bootstrap.sh

Bootstrap.sh will prompt for the cloud controller URL (e.g. api.stackato-wxyz.local).  
After both scripts finish executing, the service and couchdb should start running.

## Edit the config files

Some settings in the default files in the config/ directory may need to be modified. This may include:

* `mbus`: This should match the setting for other services. You can check
  the correct setting using `kato config get redis_node mbus`

## Verify the service

Once the couchdb service has been enabled and started in kato, clients
targeting the system should be able to see it listed in the System
Services output:

    $ stackato services
  
    ============== System Services ==============
   
    +------------+---------+------------------------------------------+
    | Service    | Version | Description                              |
    +------------+---------+------------------------------------------+
    | couchdb    | 1.5.0   | CouchDB service                          |
    | filesystem | 1.0     | Persistent filesystem service            |
    | memcached  | 1.4     | Memcached in-memory object cache service |
    | mongodb    | 2.0     | MongoDB NoSQL store                      |
    | postgresql | 9.1     | PostgreSQL database service              |
    | rabbitmq   | 2.4     | RabbitMQ message queue                   |
    | redis      | 2.4     | Redis key-value store service            |
    +------------+---------+------------------------------------------+
    
To create a new service:

    $ stackato create-service couchdb
    Creating Service [couchdb-503db]: OK
