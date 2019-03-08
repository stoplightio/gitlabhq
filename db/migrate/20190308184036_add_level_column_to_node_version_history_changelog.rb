# 20190308184036_add_level_column_to_node_version_history_changelog.rb

class AddPathColumnToNodeVersionHistoryChangelog < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      execute <<-SQL
        ALTER TABLE node_version_history_changelog ADD COLUMN level int4 NOT NULL;
      SQL
    end
  end

  def down

  end
end
