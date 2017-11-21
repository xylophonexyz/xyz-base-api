class CreateCompositions < ActiveRecord::Migration[5.0]
  def change
    create_table :compositions do |t|
      t.integer :user_id
      t.integer :parent_id
      t.string :title
      t.datetime :published_on
      t.text :metadata, limit: 4294967295
      t.timestamps
    end
    add_index :compositions, :user_id
    add_index :compositions, :parent_id
  end
end
