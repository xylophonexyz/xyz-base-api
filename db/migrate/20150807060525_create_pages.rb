class CreatePages < ActiveRecord::Migration[5.0]
  def change
    create_table :pages do |t|
      t.integer :user_id
      t.integer :composition_id
      t.string :title
      t.text :description
      t.boolean :published, default: false
      t.timestamps null: false
      t.text :metadata, limit: 4294967295
    end
    add_index :pages, :user_id
    add_index :pages, :composition_id
  end
end
