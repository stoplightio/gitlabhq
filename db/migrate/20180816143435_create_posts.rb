class CreatePosts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  class Post < ActiveRecord::Base
    enum state: [:open, :closed]
    enum type: [:discussion, :issue]
  end

  DOWNTIME = false

  def up
    create_table :posts do |t|
      t.integer :iid, null: false
      t.integer :project_id, null: false
      t.integer :creator_id, null: false
      t.integer :file_id

      t.string :state, null: false, default: 'open'
      t.string :type, null: false
      t.string :title
      t.string :body
      t.string :file_loc
      t.datetime :last_activity_at

      t.timestamps null: true

      t.foreign_key :projects, column: :project_id, on_delete: :cascade
      t.foreign_key :users, column: :creator_id, on_delete: :cascade
      t.foreign_key :project_files, column: :file_id, on_delete: :cascade
      
      t.index [:project_id, :iid], unique: true
      t.index :file_id
      t.index :creator_id
      t.index :state
      t.index :created_at
    end
    
    if Gitlab::Database.postgresql?
      execute <<-SQL
        CREATE OR REPLACE FUNCTION trigger_set_post_timestamp()
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

        CREATE OR REPLACE FUNCTION trigger_set_post_iid()
        RETURNS trigger AS
        $BODY$
        BEGIN
            SELECT COALESCE(MAX(iid) + 1, 1)
            INTO NEW.iid
            FROM posts
            WHERE project_id = NEW.project_id;

            RETURN NEW;
        END;
        $BODY$
        LANGUAGE 'plpgsql'
        VOLATILE;

        CREATE OR REPLACE FUNCTION trigger_set_post_last_activity_at()
        RETURNS trigger AS
        $BODY$
        BEGIN
            NEW.last_activity_at = NOW();
            RETURN NEW;
        END;
        $BODY$
        LANGUAGE 'plpgsql'
        VOLATILE;

        CREATE OR REPLACE FUNCTION trigger_set_post_last_activity_at_comments()
        RETURNS trigger AS
        $BODY$
        BEGIN
            IF (TG_OP = 'INSERT') THEN
              UPDATE posts
              SET last_activity_at = NOW()
              WHERE NEW.parent_type = 'post' AND id = NEW.parent_id;
            ELSIF (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN
              UPDATE posts
              SET last_activity_at = NOW()
              WHERE OLD.parent_type = 'post' AND id = OLD.parent_id;
            END IF;

            RETURN NEW;
        END;
        $BODY$
        LANGUAGE 'plpgsql'
        VOLATILE;

        CREATE TRIGGER trigger_set_post_timestamp
        BEFORE INSERT OR UPDATE ON posts
        FOR EACH ROW EXECUTE PROCEDURE trigger_set_post_timestamp();

        CREATE TRIGGER trigger_set_post_iid
        BEFORE INSERT ON posts
        FOR EACH ROW EXECUTE PROCEDURE trigger_set_post_iid();

        CREATE TRIGGER trigger_set_post_last_activity_at
        BEFORE INSERT OR UPDATE ON posts
        FOR EACH ROW EXECUTE PROCEDURE trigger_set_post_last_activity_at();

        CREATE TRIGGER trigger_set_post_last_activity_at_comments
        BEFORE INSERT OR UPDATE OR DELETE ON comments
        FOR EACH ROW EXECUTE PROCEDURE trigger_set_post_last_activity_at_comments();
      SQL
    end
  end

  def down
    drop_table :posts

    if Gitlab::Database.postgresql?
      execute <<-SQL
        DROP TRIGGER IF EXISTS trigger_set_post_timestamp ON posts;
        DROP TRIGGER IF EXISTS trigger_set_post_iid ON posts;
        DROP TRIGGER IF EXISTS trigger_set_post_last_activity_at ON posts;
        DROP TRIGGER IF EXISTS trigger_set_post_last_activity_at_comments ON comments;
        DROP FUNCTION IF EXISTS trigger_set_post_timestamp();
        DROP FUNCTION IF EXISTS trigger_set_post_iid();
        DROP FUNCTION IF EXISTS trigger_set_post_last_activity_at();
        DROP FUNCTION IF EXISTS trigger_set_post_last_activity_at_comments();
      SQL
    end
  end
end
