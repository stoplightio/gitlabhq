class CreateProjectFiles < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :project_files do |t|
      t.integer :project_id, null: false

      t.string :path, null: false
      t.string :branch, null: false
      t.string :spec
      t.string :lang
      t.integer :size

      t.datetime_with_timezone :created_at
      t.datetime_with_timezone :updated_at

      t.foreign_key :projects, column: :project_id, on_delete: :cascade
      
      t.index [:project_id]
      t.index [:branch, :path], unique: true
    end

    if Gitlab::Database.postgresql?
      execute <<-SQL
        CREATE OR REPLACE FUNCTION trigger_set_project_file_timestamp()
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

        CREATE TRIGGER trigger_set_project_file_timestamp
        BEFORE INSERT OR UPDATE ON project_files
        FOR EACH ROW EXECUTE PROCEDURE trigger_set_project_file_timestamp();
      SQL
    end
  end

  def down
    drop_table :project_files

    if Gitlab::Database.postgresql?
      execute <<-SQL
        DROP TRIGGER IF EXISTS trigger_set_project_file_timestamp ON project_files;
      SQL
    end
  end
end
