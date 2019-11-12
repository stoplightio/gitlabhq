# 20171108125809_create_billing_accounts.rb

# rubocop:disable all
class CreateBillingAccounts < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    create_table :billing_accounts do |t|
      t.integer :namespace_id
      t.integer :recurly_account_id
      t.string :recurly_account_state
      t.string :recurly_subscription_id
      t.string :recurly_subscription_state
      t.string :recurly_plan

      t.timestamps null: true
    end

     add_index "billing_accounts", ["namespace_id"], name: "index_billing_accounts_on_namespace_id", using: :btree
  end

  def down
    drop_table :billing_accounts
  end
end
