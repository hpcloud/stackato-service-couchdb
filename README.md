CouchDB Service for Stackato
=========================

This CouchDB Service for Stackato is under active development. It is based partly on the Echo Service sample code.

This sample is based on [cloudfoundry/vcap-services/echo](https://github.com/cloudfoundry/vcap-services/tree/master/echo)
with some additional configuration (e.g for `kato` and `supervisord`)
and other minor differences. The instructions here are for [Stackato
2.10.6](http://www.activestate.com/stackato/get_stackato).

## Prerequisites

Make sure you followed the Stackato [quickstart guide](http://docs.stackato.com/quick-start/index.html).

**Tip:**: To find out the Cloud Controller API URL for a microcloud, run this command on the VM: 

    echo api.`hostname`.local

## Copying/Cloning the Service to Stackato

Log in to the Stackato VM (micro cloud or service node) as the 'stackato' user and clone this repository 
directly into a `vcap/services/couchdb` directory:

    $ git clone https://github.com/shsu/stackato-couchdb.git /s/vcap/services/couchdb

**Alternatively**, you can scp a local checkout of stackato-couchdb to Stackato using SCP.

## Customize CouchDB (Optional)

You can customize your couchdb installation by editing `resources/default.ini` before running the install script.

## Installation

Execute `scripts/install-couchdb.sh` and `scripts/bootstrap.sh` **on the stackato VM**:

    $ cd /s/vcap/services/couchdb/scripts
    $ sudo ./install-couchdb.sh
    $ ./bootstrap.sh

`scripts/bootstrap.sh` will prompt for the Cloud Controller API URL.
After both scripts finish executing, the service and couchdb should start running.

## Verify the service

Once the couchdb service has been enabled and started in kato, clients targeting 
the system should be able to see it listed in the System Services output:

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

## Edit the config files (Optional)

Some settings in the default files in the config/ directory may need to be modified. This may include:

* `mbus`: This should match the setting for other services. You can check
  the correct setting using:

      kato config get couchdb_node mbus

* `COUCHDB_URL`: 
