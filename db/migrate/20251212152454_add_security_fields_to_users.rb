class AddSecurityFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :failed_login_attempts, :integer, default: 0, null: false
    add_column :users, :locked_at, :datetime

    add_index :users, :locked_at
    add_index :users, :failed_login_attempts
  end
end