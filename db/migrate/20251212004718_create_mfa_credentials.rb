class CreateMfaCredentials < ActiveRecord::Migration[7.1]
  def change
    create_table :mfa_credentials do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :secret_key, null: false
      t.boolean :enabled, default: false, null: false
      t.datetime :enabled_at

      t.timestamps
    end
  end
end