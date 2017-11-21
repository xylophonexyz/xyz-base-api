class CreateComponentCollections < ActiveRecord::Migration[5.0]
  def change
    create_table :component_collections do |t|
      t.integer :collectible_id
      t.string :collectible_type
      t.integer :index, default: 0
      t.string :type
      t.text :metadata, limit: 4294967295
      t.timestamps
    end
    add_index :component_collections, :collectible_id
    add_index :component_collections, :collectible_type
  end
end
