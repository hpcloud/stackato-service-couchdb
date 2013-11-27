# Copyright (c) 2009-2011 VMware, Inc.
require 'couchdb_service/common'

class VCAP::Services::Couchdb::Provisioner < VCAP::Services::Base::Provisioner

  include VCAP::Services::Couchdb::Common

end
