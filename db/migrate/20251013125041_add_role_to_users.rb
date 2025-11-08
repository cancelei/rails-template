class AddRoleToUsers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :users, :role, :string, default: "tourist"
    add_column :users, :phone, :string
    add_column :users, :last_login_at, :datetime
    add_index :users, :role, algorithm: :concurrently
  end
end
