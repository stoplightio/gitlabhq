# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RenameHistoryToSnapshot < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      execute <<-SQL
        alter table node_version_history rename to node_version_snapshot;
        alter index node_version_history_pkey rename to node_version_snapshot_pkey;
        alter table node_version_snapshot rename constraint node_version_history_commit_id_fkey to node_version_snapshot_commit_id;
        alter table node_version_snapshot rename constraint node_version_history_node_version_id_fkey to node_version_snapshot_node_version_id;
        alter index node_version_history_node_version_id_commit_id_idx rename to node_version_snapshot_node_version_id_commit_id_idx;
        
        alter table node_version_history_changelog rename to node_version_snapshot_changelog;
        alter table node_version_snapshot_changelog rename column node_version_history_id to node_version_snapshot_id;
        alter index node_version_history_changelog_pkey rename to node_version_snapshot_changelog_pkey;
        alter table node_version_snapshot_changelog rename constraint node_version_history_changelog_node_version_history_id_fkey to node_version_snapshot_changelog_node_version_snapshot_id_fkey;
        alter index node_version_history_changelog_node_version_history_id_message_ rename to node_version_snapshot_changelog_snapshot_id_message_idx;
        
        alter table node_version_history_validations rename to node_version_snapshot_validations;
        alter table node_version_snapshot_validations rename column node_version_history_id to node_version_snapshot_id;
        alter index node_version_history_validations_pkey rename to node_version_snapshot_validations_pkey;
        alter table node_version_snapshot_validations rename constraint node_version_history_validations_node_version_history_id_fkey to node_version_snapshot_validations_node_version_snapshot_id_fkey;
        alter index node_version_history_validations_node_ver_hist_id_data_idx rename to node_version_snapshot_validations_snapshot_id_data_idx;
      SQL
    end
  end

  def down
    if Gitlab::Database.postgresql?
      execute <<-SQL
        alter index node_version_snapshot_validations_snapshot_id_data_idx rename to node_version_history_validations_node_ver_hist_id_data_idx ;
        alter table node_version_snapshot_validations rename constraint node_version_snapshot_validations_node_version_snapshot_id_fkey to node_version_history_validations_node_version_history_id_fkey;
        alter index node_version_snapshot_validations_pkey rename to node_version_history_validations_pkey ;
        alter table node_version_snapshot_validations rename column node_version_snapshot_id to node_version_history_id;
        alter table node_version_snapshot_validations rename to node_version_history_validations;

        alter index node_version_snapshot_changelog_snapshot_id_message_idx rename to node_version_history_changelog_node_version_history_id_message_;
        alter table node_version_snapshot_changelog rename constraint node_version_snapshot_changelog_node_version_snapshot_id_fkey to node_version_history_changelog_node_version_history_id_fkey;
        alter index node_version_snapshot_changelog_pkey rename to node_version_history_changelog_pkey;
        alter table node_version_snapshot_changelog rename column node_version_snapshot_id to node_version_history_id;
        alter table node_version_snapshot_changelog rename to node_version_history_changelog;

        alter index node_version_snapshot_node_version_id_commit_id_idx rename to node_version_history_node_version_id_commit_id_idx;
        alter table node_version_snapshot rename constraint node_version_snapshot_node_version_id to node_version_history_node_version_id_fkey;
        alter table node_version_snapshot rename constraint node_version_snapshot_commit_id to node_version_history_commit_id_fkey;
        alter index node_version_snapshot_pkey rename to node_version_history_pkey;
        alter table node_version_snapshot rename to node_version_history;
      SQL
    end
  end
end
