# 20190319190817_update_node_version_history_changelog_columns.rb

class UpdateNodeVersionHistoryChangelogColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      execute <<-SQL

      ALTER TABLE node_version_history_changelog ADD COLUMN org_id int4 NOT NULL;
      ALTER TABLE node_version_history_changelog ADD COLUMN project_id int4 NOT NULL;
      ALTER TABLE node_version_history_changelog ADD COLUMN branch_id int4 NOT NULL;
      ALTER TABLE node_version_history_changelog ADD COLUMN node_type text;

      ALTER TABLE node_version_history_changelog ADD CONSTRAINT node_version_history_changelog_org_id FOREIGN KEY (org_id) REFERENCES namespaces(id) ON DELETE CASCADE;
      ALTER TABLE node_version_history_changelog ADD CONSTRAINT node_version_history_changelog_project_id FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;

      CREATE INDEX node_version_history_changelog_org_id_idx ON node_version_history_changelog (org_id);
      CREATE INDEX node_version_history_changelog_project_id_idx ON  node_version_history_changelog (project_id);
      CREATE INDEX node_version_history_changelog_node_type_idx ON node_version_history_changelog (node_type);
      SQL
    end
  end

  def down

  end
end
