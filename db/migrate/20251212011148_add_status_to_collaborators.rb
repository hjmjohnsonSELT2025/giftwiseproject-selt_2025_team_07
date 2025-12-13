class AddStatusToCollaborators < ActiveRecord::Migration[7.1]
  def change
    add_column :collaborators, :status, :string, null: false, default: "pending"
    add_index  :collaborators, :status
  end
end
