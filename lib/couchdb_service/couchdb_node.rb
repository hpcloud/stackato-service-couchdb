# Copyright (c) 2009-2011 VMware, Inc.
require "fileutils"
require "logger"
require "datamapper"
require "uuidtools"

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
  end

  def initialize(options)
    super(options)

    @local_db = options[:local_db]
    @port = options[:port]
    @base_dir = options[:base_dir]
    @supported_versions = ["1.0"]
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

    begin
	  #here we add the start_couchdb for now
	  start_couchdb(instance)
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

  # edit. We are starting the couchDB instance here
  def start_couchdb(instance)
    pidfile = pid_file
    exec_path = "/usr/local/bin/couchdb"

    # run couchdb, setting the pidfile path
    cmd = "#{exec_path} -p #{pidfile} -b"
    @logger.debug("*** starting main process: #{cmd}")

    env = {}

    pid = Process.spawn(env, cmd)
	
    # In parent, detach the child
    Process.detach(pid)

    # wait for the process to start
    sleep(3)

    # grab the pid from the spawned instance
    instance.pid = get_pid

    @logger.debug("CouchDB started with pid #{pid}")

    @logger.debug("*** end start_couchdb")
  end
  
  def pid_file
	return File.join(@base_dir, 'pidfile')
  end
  
  def get_pid()
    # read from the pidfile
    file = File.new(pid_file, "r")
    pid = file.gets
    file.close
    return pid.to_i
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
