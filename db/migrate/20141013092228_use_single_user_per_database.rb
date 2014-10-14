class UseSingleUserPerDatabase < ActiveRecord::Migration
  def change
    add_column :service_instances, :service_username, :string
    add_column :service_instances, :service_password, :string
  end
end
