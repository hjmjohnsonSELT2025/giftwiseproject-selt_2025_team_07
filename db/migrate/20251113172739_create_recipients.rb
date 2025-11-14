class CreateRecipients < ActiveRecord::Migration[7.1]
  def change
    create_table :recipients do |t|
      t.string :name
      t.integer :age
      t.string :relationship
      t.text :likes
      t.text :dislikes
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
