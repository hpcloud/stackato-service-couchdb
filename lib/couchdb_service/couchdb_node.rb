# Copyright (c) 2009-2011 VMware, Inc.
require "fileutils"
require "logger"
require "datamapper"
require "uuidtools"
require "rest_client"
require "securerandom"
require "digest/sha1"
require "json"

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
    property :user,       String
    property :password,   String
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
      instance.name = "db-" + UUIDTools::UUID.random_create.to_s
    end

    # creating the database
    create_database(instance)
    
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
  
  def create_database(instance)
    db_name = instance.name

    RestClient.put("http://#{@couchdb_admin}:#{@couchdb_password}@#{@couchdb_hostname}/#{db_name}",'') { |response, request, result, &block|
      case response.code
      when 200
        @logger.info("200: Request completed successfully.")
      when 201
        @logger.info("201: Document created successfully.")
      when 202
        @logger.info("202: Request for database compaction completed successfully.")
      when 304
        @logger.info("304: Etag not modified since last update.")
      else
        # 4xx and 5xx HTTP Errors
        @logger.error(response.code.to_s + " HTTP Error\n" + response.to_s);
        # pass the response as a argument of a method in order to determine what specific error to throw. (disk full, illegal name, etc.)
        raise "Cannot Create Database."
      end
    }
    
    # make dummy content in _security
    initial_authorization = {'admins' => {'names' => [], 'roles' => []}, 'members' => {'names' => [], 'roles' => []}}
    RestClient.put("http://#{@couchdb_admin}:#{@couchdb_password}@#{@couchdb_hostname}/#{db_name}/_security", 
      initial_authorization.to_json, :content_type => :json) { |response, request, result, &block|
          case response.code
          when 200
            @logger.info("200: Request completed successfully.")
          when 201
            @logger.info("201: Document created successfully.")
          when 202
            @logger.info("202: Request for database compaction completed successfully.")
          when 304
            @logger.info("304: Etag not modified since last update.")
          else
            # 4xx and 5xx HTTP Errors
            @logger.error(response.code.to_s + " HTTP Error\n" + response.to_s);
            raise "Cannot Perform Authorization of User."
          end
    }
  end
  
  def unprovision(name, credentials = [])
    return if name.nil?
    @logger.debug("Unprovision couchdb service: #{name}")
    instance = get_instance(name)
  
  #delete the database
  delete_database(instance)
    
  destroy_instance(instance)
    true
  end
  
  def delete_database(instance)
    db_name = instance.name
    RestClient.delete("http://#{@couchdb_admin}:#{@couchdb_password}@#{@couchdb_hostname}/#{db_name}") { |response, request, result, &block|
      case response.code
      when 200
        @logger.info("200: Request completed successfully.")
      when 201
        @logger.info("201: Document created successfully.")
      when 202
        @logger.info("202: Request for database compaction completed successfully.")
      when 304
        @logger.info("304: Etag not modified since last update.")
      else
        # 4xx and 5xx HTTP Errors
        @logger.error(response.code.to_s + " HTTP Error\n" + response.to_s);
        # pass the response as a argument of a method in order to determine what specific error to throw. (disk full, illegal name, etc.)
        raise "Cannot Delete Database."
      end
    }
    
  end
  
  def bind(name, binding_options, credential = nil)
    instance = nil
    if credential
      instance = get_instance(credential["name"])
    else
      instance = get_instance(name)
    end
    
    user = "user-" + SecureRandom.hex(8)
    password = SecureRandom.hex(8)
    
    create_database_user(name, user, password)
    
    generate_bind_credentials(name, user, password)
  end

  def create_database_user(name, user, password)
    user_authentication = { 
      '_id' => "org.couchdb.user:#{user}", 
      'type' => 'user', 
      'name' => user, 
      'roles' => [], 
      'password' => password 
    }
    
    # insert user to _users
    RestClient.put("http://#{@couchdb_admin}:#{@couchdb_password}@#{@couchdb_hostname}/_users/org.couchdb.user:#{user}", 
      user_authentication.to_json, :content_type => :json) { |response, request, result, &block|
          case response.code
          when 200
            @logger.info("200: Request completed successfully.")
          when 201
            @logger.info("201: Document created successfully.")
          when 202
            @logger.info("202: Request for database compaction completed successfully.")
          when 304
            @logger.info("304: Etag not modified since last update.")
          else
            # 4xx and 5xx HTTP Errors
            @logger.error(response.code.to_s + " HTTP Error\n" + response.to_s);
            raise "Cannot Create User."
          end
    }

    # get contents of _security
    securityContent = RestClient.get("http://#{@couchdb_admin}:#{@couchdb_password}@#{@couchdb_hostname}/#{name}/_security", 
      {:accept => :json}){ |response, request, result, &block|
          case response.code
          when 200
            @logger.info("200: Request completed successfully.")
          when 201
            @logger.info("201: Document created successfully.")
          when 202
            @logger.info("202: Request for database compaction completed successfully.")
          when 304
            @logger.info("304: Etag not modified since last update.")
          else
            # 4xx and 5xx HTTP Errors
            @logger.error(response.code.to_s + " HTTP Error\n" + response.to_s);
            raise "Cannot get _security contents."
          end
    }
    
    security = JSON.parse(securityContent)
    
    # inserting authorization for new user
    security["admins"]["names"].push(user.to_s)

    # updating _security
    RestClient.put("http://#{@couchdb_admin}:#{@couchdb_password}@#{@couchdb_hostname}/#{name}/_security", 
      security.to_json, :content_type => :json) { |response, request, result, &block|
          case response.code
          when 200
            @logger.info("200: Request completed successfully.")
          when 201
            @logger.info("201: Document created successfully.")
          when 202
            @logger.info("202: Request for database compaction completed successfully.")
          when 304
            @logger.info("304: Etag not modified since last update.")
          else
            # 4xx and 5xx HTTP Errors
            @logger.error(response.code.to_s + " HTTP Error\n" + response.to_s);
            raise "Cannot Perform Authorization of User."
          end
    }
  end
  
  def unbind(credential)
    @logger.debug("Unbind service: #{credential.inspect}")
    name, user, password = %w(name username password).map{|k| credential[k]}
    delete_database_user(name, user, password)
    true
  end

  def delete_database_user(name, user, password)
    # get contents of _security
    securityContent = RestClient.get("http://#{@couchdb_admin}:#{@couchdb_password}@#{@couchdb_hostname}/#{name}/_security", 
      {:accept => :json}) { |response, request, result, &block|
          case response.code
          when 200
            @logger.info("200: Request completed successfully.")
          when 201
            @logger.info("201: Document created successfully.")
          when 202
            @logger.info("202: Request for database compaction completed successfully.")
          when 304
            @logger.info("304: Etag not modified since last update.")
          else
            # 4xx and 5xx HTTP Errors
            @logger.error(response.code.to_s + " HTTP Error\n" + response.to_s);
            raise "Cannot Get Authorization File."
          end
      }
    
    security = JSON.parse(securityContent)
    
    # delete user from security
    security["admins"]["names"].delete("#{user}")
    
    # update _security
    RestClient.put("http://#{@couchdb_admin}:#{@couchdb_password}@#{@couchdb_hostname}/#{name}/_security", 
      security.to_json, :content_type => :json) { |response, request, result, &block|
          case response.code
          when 200
            @logger.info("200: Request completed successfully.")
          when 201
            @logger.info("201: Document created successfully.")
          when 202
            @logger.info("202: Request for database compaction completed successfully.")
          when 304
            @logger.info("304: Etag not modified since last update.")
          else
            # 4xx and 5xx HTTP Errors
            @logger.error(response.code.to_s + " HTTP Error\n" + response.to_s);
            raise "Cannot Delete Authorization of User."
          end
      }
    
    # delete user authentication
    RestClient.delete("http://#{@couchdb_admin}:#{@couchdb_password}@#{@couchdb_hostname}/_users/org.couchdb.user:#{user}")
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
  
  def generate_bind_credentials(name, user, password)
    credential = {
      "name"          => name,
      "username"      => user,
      "password"      => password,
      "host"          => @couchdb_hostname,
      "database_url"  => "http://#{user}:#{password}@#{@couchdb_hostname}/#{name}"
    }
  end

end
