class CreateVotes < ActiveRecord::Migration[5.0]
  def change
    create_table :votes do |t|
      t.integer :votable_id
      t.string :votable_type
      t.integer :user_id
      t.boolean :value
      t.timestamps null: false
    end
    add_index :votes, :votable_id
    add_index :votes, :votable_type
    add_index :votes, :user_id
  end
end
