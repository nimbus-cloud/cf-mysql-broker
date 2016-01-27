module Database
  extend self

  def create(database_name)
    connection.execute("CREATE DATABASE IF NOT EXISTS #{connection.quote_table_name(database_name)}")
  end

  def drop(database_name)
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

  def exists?(database_name)
    connection.select("SHOW DATABASES LIKE '#{database_name}'").count > 0
  end

  def usage(database_name)
    res = connection.select(<<-SQL)
        SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 1)
        FROM   information_schema.tables AS tables
        WHERE tables.table_schema = '#{database_name}'
    SQL

    res.rows.first.first.to_i
  end

  def with_reconnect
    yield
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.warn(e)
    if ActiveRecord::Base.connection.active?
      raise e
    else
      reconnect_attempts = 0
      until ActiveRecord::Base.connection.active?
        reconnect_attempts += 1
        attempt_reconnect(reconnect_attempts)
      end
    end
  end

  private

  def attempt_reconnect(reconnect_attempts)
    Rails.logger.warn('No database connection, attempting to reconnect')
    ActiveRecord::Base.connection.reconnect!
  rescue Mysql2::Error => e
    Rails.logger.warn("Reconnect failed: #{e}")

    if reconnect_attempts < 20
      Kernel.sleep(3.seconds)
    else
      raise e
    end
  end

  def connection
    ActiveRecord::Base.connection
  end
end
