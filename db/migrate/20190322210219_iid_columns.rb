# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class IidColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      execute <<-SQL
        ALTER TABLE nodes add column iid text NOT NULL;
        ALTER TABLE node_version_snapshot add column iid bigint NOT NULL;
      SQL
    end
  end

  def down
    if Gitlab::Database.postgresql?
      execute <<-SQL
        ALTER TABLE node_version_snapshot drop column iid;
        ALTER TABLE nodes drop column iid;
      SQL
    end
  end
end
