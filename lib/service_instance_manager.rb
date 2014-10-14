class ServiceInstanceManager
  class ServiceInstanceNotFound < StandardError
  end

  DATABASE_PREFIX = 'cf_'.freeze

  def self.create(opts)
    guid = opts[:guid]
    plan_guid = opts[:plan_guid]

    unless Catalog.has_plan?(plan_guid)
      raise "Plan #{plan_guid} was not found in the catalog."
    end

    max_storage_mb = Catalog.storage_quota_for_plan_guid(plan_guid)

    if guid =~ /[^0-9,a-z,A-Z$-]+/
      raise 'Only GUIDs matching [0-9,a-z,A-Z$-]+ are allowed'
    end

    db_name = database_name_from_service_instance_guid(guid)
    
    service_username = SecureRandom.base64(20).gsub(/[^a-zA-Z0-9]+/, '')[0...16]
    service_password = SecureRandom.base64(20).gsub(/[^a-zA-Z0-9]+/, '')[0...16]

    Database.create(db_name)
    Database.add_user(service_username, service_password, db_name, plan_guid)
    
    ServiceInstance.create(guid: guid, plan_guid: plan_guid, max_storage_mb: max_storage_mb, db_name: db_name, service_username: service_username, service_password: service_password)
  end

  def self.destroy(opts)
    guid = opts[:guid]
    instance = ServiceInstance.find_by_guid(guid)
    raise ServiceInstanceNotFound if instance.nil?
    
    Database.remove_user(instance.service_username)
    instance.destroy
    Database.drop(database_name_from_service_instance_guid(guid))
  end

  def self.database_name_from_service_instance_guid(guid)
    "#{DATABASE_PREFIX}#{guid.gsub('-', '_')}"
  end
end
