CouchDB Service for Stackato
=========================

The Stackato CouchDB service is based on [cloudfoundry/vcap-services/echo](https://github.com/cloudfoundry/vcap-services/tree/master/echo)
with some additional configuration (e.g for `kato` and `supervisord`)
and other minor differences. The instructions here are for [Stackato
2.10.6](http://www.activestate.com/stackato/get_stackato).

## Prerequisites

Make sure you followed the [Stackato quickstart guide](http://docs.stackato.com/quick-start/index.html) before continuing.

**Tip**: To find out the Cloud Controller API URL for a **microcloud**, run this command on the stackato VM: 

    echo api.`hostname`.local

## Copying/Cloning the Service to Stackato

Log in to the Stackato VM (micro cloud or service node) as the 'stackato' user and clone this repository 
directly into a `vcap/services/couchdb` directory:

    $ git clone https://github.com/shsu/stackato-couchdb.git /s/vcap/services/couchdb

**Alternatively**, you can scp a local checkout of stackato-couchdb to Stackato.

## Apache CouchDB & Service Installation

You can customize your couchdb installation by editing `resources/default.ini` before running the install script.

Execute `scripts/install-couchdb.sh` and `scripts/bootstrap.sh` on the stackato VM:

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

## Optional Configurations:

* To have `COUCHDB_URL` available in your environment, add the following snippet of code to 
`/s/vcap/common/lib/vcap/services_env.rb` after the comment about 
"# Add individual environment variables" (around line 60):

        only_item(vcap_services['couchdb']) do |s|
            c = s[:credentials]
            e["COUCHDB_URL"] = c[:couchdb_url]
        end
        
Save the file then restart stackato components by executing: `kato restart`.

## How to use this Stackato CouchDB Service:

You will need to parse the `$VCAP_SERVICES` or `$COUCHDB_URL` (if available) environment variables.

Below is a PHP example:

    $services = getenv("VCAP_SERVICES");
    $services_json = json_decode($services,true);
    $couchdb_conf = $services_json["couchdb"][0]["credentials"];
    
    $couch_connection_url = "http://".$couchdb_conf["username"].":".$couchdb_conf["password"]."@"
        .$couchdb_conf["host"].":".$couchdb_conf["port"];
    $couch_connection_db = $couchdb_conf["name"];
