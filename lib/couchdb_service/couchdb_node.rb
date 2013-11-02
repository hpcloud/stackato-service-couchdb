# Copyright (c) 2009-2011 VMware, Inc.
require "fileutils"
require "logger"
require "datamapper"
require "uuidtools"
require "rest_client"  #rev 1 addition 31/10/13

module VCAP
  module Services
    module Couchdb
      class Node < VCAP::Services::Base::Node
      end
    end
  end
end

require "couchdb_service/common"
require "couchdb_service/couchdb_error"

class VCAP::Services::Couchdb::Node

  include VCAP::Services::Couchdb::Common
  include VCAP::Services::Couchdb

  class ProvisionedService
    include DataMapper::Resource
    property :name,       String,   :key => true
    property :user,       String  #rev 1 addition 31/10/13
    property :password,   String  #rev 1 addition 31/10/13
  end

  def initialize(options)
    super(options)

    @local_db = options[:local_db]
    @port = options[:port]
    @base_dir = options[:base_dir]
    @supported_versions = ["1.0"]
    @couchdb_admin = options[:couchdb_admin]
    @couchdb_password = options[:couchdb_password]
    @couchdb_hostname = options[:couchdb_hostname]   #rev 1 addition 31/10/13
  end

  def pre_send_announcement
    super
    FileUtils.mkdir_p(@base_dir) if @base_dir
    start_db
    @capacity_lock.synchronize do
      ProvisionedService.all.each do |instance|
        @capacity -= capacity_unit
      end
    end
  end

  def announcement
    @capacity_lock.synchronize do
      { :available_capacity => @capacity,
        :capacity_unit => capacity_unit }
    end
  end

  def provision(plan, credential = nil, version=nil)
    instance = ProvisionedService.new
    if credential
      instance.name = credential["name"]
    else
      instance.name = UUIDTools::UUID.random_create.to_s
    end

    # creating the database
    create_database(instance) #rev 1 addition 31/10/13
    
    begin
      save_instance(instance)
    rescue => e1
      @logger.error("Could not save instance: #{instance.name}, cleanning up")
      begin
        destroy_instance(instance)
      rescue => e2
        @logger.error("Could not clean up instance: #{instance.name}")
      end
      raise e1
    end

    gen_credential(instance)
  end
  
  #rev 1 addition 31/10/13
  def create_database(instance)
    db_name = instance.name
    
    RestClient.put ("http://#{@couchdb_admin}:#{@couchdb_password}@#{@couchdb_hostname}/#{db_name}", '') { |response, request, result, &block|
      case response.code
      when 200
      
      when 404
        raise "Cannot Create Database: Status Code 404"
      when 401
        raise "Cannot Create Database: Status Code 401"
      when 400
        raise "Cannot Create Database: Status Code 400"
      else
        raise "Cannot Create Database: Status Code Unknown"
      end
    }
	
  end
  
  def unprovision(name, credentials = [])
    return if name.nil?
    @logger.debug("Unprovision couchdb service: #{name}")
    instance = get_instance(name)
    destroy_instance(instance)
    true
  end

  def bind(name, binding_options, credential = nil)
    instance = nil
    if credential
      instance = get_instance(credential["name"])
    else
      instance = get_instance(name)
    end
    gen_credential(instance)
  end

  def unbind(credential)
    @logger.debug("Unbind service: #{credential.inspect}")
    true
  end

  def start_db
    DataMapper.setup(:default, @local_db)
    DataMapper::auto_upgrade!
  end

  def save_instance(instance)
    raise CouchdbError.new(CouchdbError::ECHO_SAVE_INSTANCE_FAILED, instance.inspect) unless instance.save
  end

  def destroy_instance(instance)
    raise CouchdbError.new(CouchdbError::ECHO_DESTROY_INSTANCE_FAILED, instance.inspect) unless instance.destroy
  end

  def get_instance(name)
    instance = ProvisionedService.get(name)
    raise CouchdbError.new(CouchdbError::ECHO_FIND_INSTANCE_FAILED, name) if instance.nil?
    instance
  end

  def gen_credential(instance)
    credential = {
      "host" => get_host,
      "port" => @port,
      "name" => instance.name
    }
  end
end
