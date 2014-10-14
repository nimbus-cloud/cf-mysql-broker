class Database
  def self.create(database_name)
    connection.execute("CREATE DATABASE IF NOT EXISTS #{connection.quote_table_name(database_name)}")
  end

  def self.drop(database_name)
    connection.execute("DROP DATABASE IF EXISTS #{connection.quote_table_name(database_name)}")
  end
  
  def self.add_user(username, password, database_name, plan_guid)
    max_user_connections = Catalog.connection_quota_for_plan_guid(plan_guid)
    
    grant_sql = "GRANT ALL PRIVILEGES ON #{connection.quote_table_name(database_name)}.* TO #{connection.quote(username)}@'%' IDENTIFIED BY #{connection.quote(password)}"
    grant_sql = grant_sql +  " WITH MAX_USER_CONNECTIONS #{max_user_connections}" if max_user_connections
    connection.execute(grant_sql)
    
    connection.execute('FLUSH PRIVILEGES')
  end
  
  def self.remove_user(username)
    if username != nil
      connection.execute("GRANT USAGE ON *.* TO #{connection.quote(username)}@'%'")
      connection.execute("DROP USER #{connection.quote(username)}")
      connection.execute('FLUSH PRIVILEGES')
    end
  end

  # why not "SHOW DATABASES LIKE '#{id}'" ??
  def self.exists?(database_name)
    1 == connection.select("SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE schema_name=#{connection.quote(database_name)}").rows.first.first
  end

  private

  def self.connection
    ActiveRecord::Base.connection
  end

  def connection
    self.class.connection
  end
end
