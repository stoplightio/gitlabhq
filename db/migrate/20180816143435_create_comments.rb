class CreateComments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  class Comment < ActiveRecord::Base
    enum parent_type: [:post, :commit, :pull_request, :build, :version, :release]
  end

  DOWNTIME = false

  def up
    create_table :comments do |t|
      t.integer :creator_id, null: false
      t.integer :parent_id, null: false
      t.string :parent_type, null: false
      t.string :body

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false

      t.index [:parent_type, :parent_id]
      t.index :created_at
    end

    if Gitlab::Database.postgresql?
      execute <<-SQL
        CREATE OR REPLACE FUNCTION trigger_set_comment_timestamp()
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

        CREATE TRIGGER trigger_set_comment_timestamp
        BEFORE INSERT OR UPDATE ON comments
        FOR EACH ROW EXECUTE PROCEDURE trigger_set_comment_timestamp();
      SQL
    end
  end

  def down
    drop_table :comments

    if Gitlab::Database.postgresql?
      execute <<-SQL
        DROP TRIGGER IF EXISTS trigger_set_comment_timestamp ON comments;
      SQL
    end
  end
end
