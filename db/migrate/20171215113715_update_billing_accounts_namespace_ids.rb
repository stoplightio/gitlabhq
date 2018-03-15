# 20171215113715_update_billing_accounts_namespace_ids.rb

# rubocop:disable all
class UpdateBillingAccountsNamespaceIds < ActiveRecord::Migration
  DOWNTIME = false

  def up
    remove_column :billing_accounts, :additional_namespace_ids
    add_column :billing_accounts, :additional_namespace_ids, :integer, array: true, default: []

    add_index "billing_accounts", ["additional_namespace_ids"], name: "index_billing_accounts_on_additional_namespace_ids", using: :btree
  end

  def down
  end
end
