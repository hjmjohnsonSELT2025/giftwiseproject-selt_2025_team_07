class CreateCollaborationInvites < ActiveRecord::Migration[7.1]
  def change
    create_table :collaboration_invites do |t|
      t.references :event, null: false, foreign_key: true
      t.references :inviter, null: false, foreign_key: { to_table: :users }

      t.string :invitee_email, null: false
      t.string :role,          null: false
      t.string :token,         null: false
      t.string :status,        null: false, default: "pending"

      t.datetime :sent_at
      t.datetime :accepted_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :collaboration_invites, :token, unique: true
    add_index :collaboration_invites, [:event_id, :invitee_email]
  end
end
