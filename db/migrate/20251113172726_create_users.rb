class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.integer :age
      t.string :occupation
      t.text :likes
      t.text :dislikes

      t.timestamps
    end
  end
end
