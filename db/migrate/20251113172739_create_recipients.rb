class CreateRecipients < ActiveRecord::Migration[7.1]
  def change
    create_table :recipients do |t|
      t.string  :name
      t.string  :email
      t.string  :relationship
      t.integer :age
      t.string  :gender
      t.string  :occupation
      t.text    :bio
      t.text    :hobbies
      t.text    :likes
      t.text    :favorite_categories
      t.text    :dislikes
      t.decimal :budget, precision: 10, scale: 2

      # establishes the one-to-many relationship (one user has many recipients)
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
  def down
    drop_table :recipients
  end
end
