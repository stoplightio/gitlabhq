# 20190301202346_update_node_version_history_changelog_indexes.rb

class UpdateNodeVersionHistoryChangelogIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      execute <<-SQL
        CREATE UNIQUE INDEX IF NOT EXISTS node_version_history_changelog_node_version_hisotry_id_message_idx ON node_version_history_changelog USING btree (node_version_history_id, message);
      SQL
    end
  end

  def down

  end
end
