# 20180508142803_create_domains_history.rb

# rubocop:disable all
class CreateDomainsHistory < ActiveRecord::Migration
  DOWNTIME = false

  def up
    create_table :domains_history do |t|
      t.integer :domain_id
      t.integer :build_id
      t.datetime :created_at, null: false
    end

     add_index "domains_history", ["build_id"], name: "index_domains_history_on_build_id", using: :btree
     add_index "domains_history", ["domain_id"], name: "index_domains_history_on_domain_id", using: :btree
  end

  def down
    drop_table :domains
  end
end