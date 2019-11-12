# 20171130082115_update_billing_accounts.rb

# rubocop:disable all
class UpdateBillingAccounts < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    drop_table :billing_accounts

    create_table :billing_accounts do |t|
      t.string :provider

      t.integer :namespace_id
      t.string :namespace_type
      t.integer :additional_namespace_ids, array: true, default: []

      t.boolean :delinquent

      # account
      #   business_vat_id
      #   email
      #   created
      t.json :account
      t.string :account_id

      # card
      #   brand
      #   last4
      #   country
      #   exp_month
      #   exp_year
      t.json :card
      t.string :card_id

      # subscription
      #   status
      #   created
      #   items
      #     id
      #     name
      #     amount
      #     created
      #     interval
      #     quantity
      t.json :subscription
      t.string :subscription_id

      # discount
      #   coupon_id
      #   coupon_amount_off
      #   coupon_percent_off
      #   start
      #   end
      t.json :discount

      t.timestamps null: true
    end

     add_index "billing_accounts", ["namespace_id"], name: "index_billing_accounts_on_namespace_id", using: :btree
     add_index "billing_accounts", ["account_id"], name: "index_billing_accounts_on_account_id", using: :btree, unique: true
     add_index "billing_accounts", ["additional_namespace_ids"], name: "index_billing_accounts_on_additional_namespace_ids", using: :btree
  end

  def down

  end
end
