class CreateBillingAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :billing_accounts do |t|
      t.integer :user_id
      t.string :customer_id
      t.text :metadata, limit: 4.megabytes - 1
      t.timestamps
    end
  end
end
