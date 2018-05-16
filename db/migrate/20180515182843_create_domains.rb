# 20180515182843_create_domains.rb

# rubocop:disable all
class CreateDomains < ActiveRecord::Migration
  DOWNTIME = false

  def up
    create_table :domains do |t|
      t.integer :namespace_id
      t.integer :project_id
      t.integer :active_build_id
      t.string :hostname
      t.string :ssl_path
      t.boolean :custom_ssl

      t.timestamps null: true
    end

    add_index "domains", ["namespace_id"], name: "index_domains_on_namespace_id", using: :btree
    add_index "domains", ["hostname"], name: "index_domains_on_hostname", using: :btree, unique: true
    add_index "domains", ["project_id"], name: "index_domains_on_project_id", using: :btree
  end

  def down
    drop_table :domains
  end
end