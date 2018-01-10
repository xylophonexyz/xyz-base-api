class ChangeComponentTextColumnLimit < ActiveRecord::Migration[5.1]
  def up
    change_column :components, :media, :text, limit: 16.megabytes - 1
    change_column :components, :metadata, :text, limit: 4.megabytes - 1
    change_column :compositions, :metadata, :text, limit: 4.megabytes - 1
    change_column :component_collections, :metadata, :text, limit: 4.megabytes - 1
    change_column :users, :metadata, :text, limit: 4.megabytes - 1
    change_column :pages, :metadata, :text, limit: 4.megabytes - 1
  end

  def down
    change_column :components, :media, :text, limit: 4294967295
    change_column :components, :metadata, :text, limit: 4294967295
    change_column :compositions, :metadata, :text, limit: 4294967295
    change_column :component_collections, :metadata, :text, limit: 4294967295
    change_column :users, :metadata, :text, limit: 4294967295
    change_column :pages, :metadata, :text, limit: 4294967295
  end
end
