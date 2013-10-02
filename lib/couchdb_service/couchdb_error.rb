# Copyright (c) 2009-2011 VMware, Inc.
module VCAP
  module Services
    module Couchdb
      class COUCHDBError < VCAP::Services::Base::Error::ServiceError
        COUCHDB_SAVE_INSTANCE_FAILED        = [32100, HTTP_INTERNAL, "Could not save instance: %s"]
        COUCHDB_DESTROY_INSTANCE_FAILED     = [32101, HTTP_INTERNAL, "Could not destroy instance: %s"]
        COUCHDB_FIND_INSTANCE_FAILED        = [32102, HTTP_NOT_FOUND, "Could not find instance: %s"]
        COUCHDB_START_INSTANCE_FAILED       = [32103, HTTP_INTERNAL, "Could not start instance: %s"]
        COUCHDB_STOP_INSTANCE_FAILED        = [32104, HTTP_INTERNAL, "Could not stop instance: %s"]
        COUCHDB_INVALID_PLAN                = [32105, HTTP_INTERNAL, "Invalid plan: %s"]
        COUCHDB_CLEANUP_INSTANCE_FAILED     = [32106, HTTP_INTERNAL, "Could not cleanup instance, the reasons: %s"]
      end
    end
  end
end
