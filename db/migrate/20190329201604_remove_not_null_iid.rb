# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveNotNullIid < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      execute <<-SQL
        ALTER TABLE nodes ALTER COLUMN iid drop not null;
        ALTER TABLE node_version_snapshot ALTER COLUMN iid drop not null;
      SQL
    end
  end

  def down
    if Gitlab::Database.postgresql?
      execute <<-SQL
        ALTER TABLE nodes ALTER COLUMN iid set not null;
        ALTER TABLE node_version_snapshot ALTER COLUMN iid set not null;
      SQL
    end
  end
end
