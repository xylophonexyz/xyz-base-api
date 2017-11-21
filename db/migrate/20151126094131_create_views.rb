class CreateViews < ActiveRecord::Migration[5.0]
  def change
    create_table :views do |t|
      t.integer :viewable_id
      t.string :viewable_type
      t.belongs_to :user
      t.timestamps null: false
    end
    add_index :views, [:viewable_id, :viewable_type]
  end
end
