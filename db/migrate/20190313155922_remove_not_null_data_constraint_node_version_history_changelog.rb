# 20190313155922_remove_not_null_data_constraint_node_version_history_changelog.rb

class RemoveNotNullDataConstraintNodeVersionHistoryChangelog < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      execute <<-SQL
        ALTER TABLE node_version_history_changelog ALTER data DROP NOT NULL;
      SQL
    end
  end

  def down

  end
end
