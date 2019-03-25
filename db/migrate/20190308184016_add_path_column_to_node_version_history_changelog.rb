# 20190308184016_add_path_column_to_node_version_history_changelog.rb

class AddPathColumnToNodeVersionHistoryChangelog < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      execute <<-SQL
        ALTER TABLE node_version_history_changelog ADD COLUMN path text NOT NULL;
      SQL
    end
  end

  def down
    if Gitlab::Database.postgresql?
      execute <<-SQL
        ALTER TABLE node_version_history_changelog DROP COLUMN path;
      SQL
    end
  end
end
