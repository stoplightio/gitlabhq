# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddOrgIdToNodesNodeIdToNodeVersionSnapshot < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      execute <<-SQL
        ALTER TABLE nodes ADD COLUMN org_id bigint NOT NULL;
        ALTER TABLE nodes ADD CONSTRAINT nodes_org_id_fkey FOREIGN KEY (org_id) REFERENCES namespaces(id) ON DELETE CASCADE;
        ALTER TABLE nodes ALTER COLUMN iid SET NOT NULL;
        CREATE UNIQUE INDEX IF NOT EXISTS nodes_iid_org_id_idx ON nodes USING btree (iid, org_id);
        
        ALTER TABLE node_version_snapshot ADD COLUMN node_id bigint NOT NULL;
        ALTER TABLE node_version_snapshot ADD CONSTRAINT node_version_snapshot_node_id_fkey FOREIGN KEY (node_id) REFERENCES nodes(id) ON DELETE CASCADE;
        ALTER TABLE node_version_snapshot ALTER COLUMN iid SET NOT NULL;
        CREATE UNIQUE INDEX IF NOT EXISTS node_version_snapshot_iid_node_id_idx ON node_version_snapshot USING btree (iid, node_id);
      SQL
    end
  end

  def down
    if Gitlab::Database.postgresql?
      execute <<-SQL
        DROP INDEX node_version_snapshot_iid_node_id_idx;
        ALTER TABLE node_version_snapshot ALTER COLUMN iid DROP NOT NULL;
        ALTER TABLE node_version_snapshot DROP CONSTRAINT node_version_snapshot_node_id_fkey;
        ALTER TABLE node_version_snapshot DROP COLUMN node_id;

        DROP INDEX nodes_iid_org_id_idx;
        ALTER TABLE nodes ALTER COLUMN iid DROP NOT NULL;
        ALTER TABLE nodes DROP CONSTRAINT nodes_org_id_fkey;
        ALTER TABLE nodes DROP COLUMN org_id;
      SQL
    end
  end
end
