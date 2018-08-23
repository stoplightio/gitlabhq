# 20180726185641_create_docs_table.rb

# rubocop:disable all
class CreateDocsTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :docs do |t|
      t.integer :org_id
      t.integer :project_id
      t.integer :live_build_id
      t.string :domain

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
          # file_path
          # base_path
      t.json :config

      t.timestamps null: true
    end

    create_table :doc_builds do |t|
      t.integer :doc_id
      t.string :app_version

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
          # file_path
          # base_path
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

      ActiveRecord::Base.transaction do
        execute <<-EOF
            CREATE OR REPLACE FUNCTION trigger_set_timestamp()
            RETURNS trigger AS
            $BODY$
            BEGIN
              IF NEW.created_at IS NULL then
                NEW.created_at = NOW();
              END IF;

              NEW.updated_at = NOW();
              RETURN NEW;
            END;
            $BODY$
            LANGUAGE 'plpgsql'
            VOLATILE;

            CREATE TRIGGER trigger_set_timestamp
            BEFORE INSERT OR UPDATE ON docs
            FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();

            CREATE TRIGGER trigger_set_timestamp
            BEFORE INSERT OR UPDATE ON doc_builds
            FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();
        EOF
      end
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
    add_index "docs", ["domain"], name: "index_docs_on_domain", using: :btree, unique: true
    add_index "docs", ["project_id"], name: "index_docs_on_project_id", using: :btree

    # doc_builds indexes
    add_index "doc_builds", ["doc_id"], name: "index_doc_builds_on_doc_id", using: :btree
  end

  def down
    drop_table :doc_builds
    drop_table :docs

    if Gitlab::Database.postgresql?
      execute <<-EOF
        DROP TRIGGER IF EXISTS trigger_set_timestamp ON docs;
        DROP TRIGGER IF EXISTS trigger_set_timestamp ON doc_builds;
        DROP FUNCTION IF EXISTS trigger_set_timestamp();
      EOF
    end
  end
end