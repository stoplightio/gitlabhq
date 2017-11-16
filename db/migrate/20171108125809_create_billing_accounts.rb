# 20171108125809_create_billing_accounts.rb

# rubocop:disable all
class CreateBillingAccounts < ActiveRecord::Migration
  DOWNTIME = false

  def up
    execute <<-SQL
      CREATE TYPE recurly_account_state AS ENUM ('active', 'closed');
      CREATE TYPE recurly_subscription_state AS ENUM ('active', 'canceled', 'future', 'expired');
      CREATE TYPE recurly_plan AS ENUM ('developer', 'team', 'business');
    SQL

    create_table :billing_accounts do |t|
      t.integer :namespace_id
      t.integer :recurly_account_id
      t.column :recurly_account_state, :recurly_account_state
      t.string :recurly_subscription_id
      t.column :recurly_subscription_state, :recurly_subscription_state
      t.column :recurly_plan, :recurly_plan

      t.timestamps null: true
    end

     add_index "billing_accounts", ["namespace_id"], name: "index_billing_accounts_on_namespace_id", using: :btree, unique: true
  end

  def down
    drop_table :billing_accounts

    execute <<-SQL
      DROP TYPE recurly_account_state;
      DROP TYPE recurly_subscription_state;
      DROP TYPE recurly_plan;
    SQL
  end
end
