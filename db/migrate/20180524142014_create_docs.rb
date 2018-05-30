# 20180524142014_create_docs.rb

# rubocop:disable all
class CreateDocs < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :docs do |t|
      t.integer :org_id
      t.integer :project_id
      t.integer :live_build_id
      t.string :hostname
      t.string :ssl_path
      t.boolean :custom_ssl

      # config
          # integration
            # segment
            # intercom
            # ga
          # auth
            # default
            # basic
            # saml
            # auth0
      t.json :config

      t.timestamps null: true
    end

    create_table :doc_builds do |t|
      t.integer :doc_id
      t.string :ref
      t.string :file_path

      # status
        # code
        # message
      t.json :status

      # config
          # integration
            # segment
            # intercom
            # google_analytics
          # auth
            # default
            # basic
            # saml
            # auth0
      t.json :config

      t.timestamps null: true
    end

    if Gitlab::Database.postgresql?
      execute %q{
        ALTER TABLE "doc_builds"
          ADD CONSTRAINT "doc_builds_doc_id_fkey"
          FOREIGN KEY ("doc_id")
          REFERENCES "docs" ("id")
          ON DELETE CASCADE
          NOT VALID;
      }
    else
      execute %q{
        ALTER TABLE doc_builds
          ADD CONSTRAINT doc_builds_doc_id_fkey
          FOREIGN KEY (doc_id)
          REFERENCES docs (id)
          ON DELETE CASCADE;
      }
    end

    # docs indexes
    add_index "docs", ["org_id"], name: "index_docs_on_org_id", using: :btree
    add_index "docs", ["hostname"], name: "index_docs_on_hostname", using: :btree, unique: true
    add_index "docs", ["project_id"], name: "index_docs_on_project_id", using: :btree

    # doc_builds indexes
    add_index "doc_builds", ["doc_id"], name: "index_doc_builds_on_doc_id", using: :btree
  end

  def down
    drop_table :doc_builds
    drop_table :docs
  end
end