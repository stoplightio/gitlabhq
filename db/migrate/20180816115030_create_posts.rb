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

      t.datetime_with_timezone :created_at
      t.datetime_with_timezone :updated_at

      t.foreign_key :projects, column: :project_id, on_delete: :cascade
      t.foreign_key :users, column: :creator_id, on_delete: :cascade
      # TODO: uncomment this after files migrations will be implemented
      # t.foreign_key :files, column: :file_id, on_delete: :cascade
      
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

        CREATE TRIGGER trigger_set_post_iid
        BEFORE INSERT OR UPDATE ON posts
        FOR EACH ROW EXECUTE PROCEDURE trigger_set_post_iid();
        
        CREATE TRIGGER trigger_set_post_timestamp
        BEFORE INSERT OR UPDATE ON posts
        FOR EACH ROW EXECUTE PROCEDURE trigger_set_post_timestamp();
      SQL
    end
  end

  def down
    drop_table :posts

    if Gitlab::Database.postgresql?
      execute <<-SQL
        DROP TRIGGER IF EXISTS trigger_set_post_iid ON posts;
        DROP TRIGGER IF EXISTS trigger_set_post_timestamp ON posts;
        DROP FUNCTION IF EXISTS trigger_set_post_iid();
      SQL
    end
  end
end
