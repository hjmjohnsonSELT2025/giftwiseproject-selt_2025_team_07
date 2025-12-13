class CreateBackupCodes < ActiveRecord::Migration[7.1]
  def change
    create_table :backup_codes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code_digest, null: false
      t.boolean :used, default: false, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :backup_codes, [:user_id, :code_digest], unique: true
  end
end