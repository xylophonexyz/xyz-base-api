class CreateComponents < ActiveRecord::Migration[5.0]
  def change
    create_table :components do |t|
      t.integer :component_collection_id
      t.text :media
      t.boolean :media_processing
      t.string :type
      t.integer :index, default: 0
      t.text :metadata, limit: 4294967295
      t.timestamps
    end
    add_index :components, :component_collection_id
  end
end
