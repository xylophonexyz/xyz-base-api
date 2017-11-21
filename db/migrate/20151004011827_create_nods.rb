class CreateNods < ActiveRecord::Migration[5.0]
  def change
    create_table :nods do |t|
      t.integer :user_id
      t.integer :noddable_id
      t.string :noddable_type
      t.timestamps null: false
    end
    add_index :nods, :user_id
    add_index :nods, [:noddable_id, :noddable_type]
  end
end
