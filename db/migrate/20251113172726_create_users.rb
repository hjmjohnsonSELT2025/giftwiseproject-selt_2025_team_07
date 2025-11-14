class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :password
      t.integer :age
      t.string :occupation
      t.text :hobbies
      t.text :likes
      t.text :dislikes

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
  def down
    drop_table :users
  end
end