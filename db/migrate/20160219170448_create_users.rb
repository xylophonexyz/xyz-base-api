class CreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table(:users) do |t|

      # user profile
      t.string :email, null: false, default: ''
      t.string :username, null: false, default: ''
      t.text :bio, limit: 4294967295
      t.string :first_name, null: false, default: ''
      t.string :last_name, null: false, default: ''
      t.text :avatar, limit: 4294967295
      t.boolean :avatar_processing
      t.text :metadata, limit: 4294967295

      # allow multiple user types via single table inheritance
      t.string :type

      t.boolean :onboarded, default: false
      t.timestamps null: false
    end

    add_index :users, :username
    add_index :users, :email, unique: true
  end
end
