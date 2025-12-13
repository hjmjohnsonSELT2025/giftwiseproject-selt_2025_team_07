# db/migrate/XXXXXX_add_security_fields_to_audit_logs.rb
#
# This migration adds security event tracking to your existing audit_logs table
# Now one table can handle both resource auditing AND security events

class AddSecurityFieldsToAuditLogs < ActiveRecord::Migration[7.1]
  def change
    # Add security-specific fields
    add_column :audit_logs, :ip_address, :string
    add_column :audit_logs, :user_agent, :string
    add_column :audit_logs, :details, :text  # JSON serialized data

    # Make user_id nullable for security events without a user (failed logins)
    change_column_null :audit_logs, :user_id, true

    # Add indexes for security queries
    add_index :audit_logs, :ip_address
    add_index :audit_logs, :action
    add_index :audit_logs, [:user_id, :action]
    add_index :audit_logs, :created_at

    # Optional: Add event_type to distinguish between resource audits and security events
    add_column :audit_logs, :event_type, :string, default: 'resource_audit'
    add_index :audit_logs, :event_type
  end

  def down
    remove_column :audit_logs, :ip_address
    remove_column :audit_logs, :user_agent
    remove_column :audit_logs, :details
    remove_column :audit_logs, :event_type
    change_column_null :audit_logs, :user_id, false

    remove_index :audit_logs, :ip_address if index_exists?(:audit_logs, :ip_address)
    remove_index :audit_logs, :action if index_exists?(:audit_logs, :action)
    remove_index :audit_logs, [:user_id, :action] if index_exists?(:audit_logs, [:user_id, :action])
    remove_index :audit_logs, :created_at if index_exists?(:audit_logs, :created_at)
    remove_index :audit_logs, :event_type if index_exists?(:audit_logs, :event_type)
  end
end