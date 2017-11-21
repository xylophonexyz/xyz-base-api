class CreateComments < ActiveRecord::Migration[5.0]
  def change
    create_table :comments do |t|
      t.string :body, default: ''
      t.integer :parent_id
      t.integer :commentable_id
      t.string :commentable_type
      t.integer :user_id
      t.boolean :disabled, default: false
      t.timestamps null: false
    end
    add_index :comments, :commentable_id
    add_index :comments, :commentable_type
    add_index :comments, :user_id
  end
end
