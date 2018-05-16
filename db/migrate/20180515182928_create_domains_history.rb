# 20180515182928_create_domains_history.rb

# rubocop:disable all
class CreateDomainsHistory < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :domains_history do |t|
      t.integer :domain_id
      t.integer :build_id
      t.string :event
      t.json :data

      t.timestamps null: true
    end

      if Gitlab::Database.postgresql?
        execute %q{
          ALTER TABLE "domains_history"
            ADD CONSTRAINT "domains_history_domain_id_fkey"
            FOREIGN KEY ("domain_id")
            REFERENCES "domains" ("id")
            ON DELETE CASCADE
            NOT VALID;
        }
      else
        execute %q{
          ALTER TABLE domains_history
            ADD CONSTRAINT domains_history_domain_id_fkey
            FOREIGN KEY (domain_id)
            REFERENCES domains (id)
            ON DELETE CASCADE;
        }
      end

     add_index "domains_history", ["build_id"], name: "index_domains_history_on_build_id", using: :btree
     add_index "domains_history", ["domain_id"], name: "index_domains_history_on_domain_id", using: :btree
  end

  def down
    drop_table :domains_history
  end
end