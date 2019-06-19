class ChangeNamespaceTagNamespaceId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'This migration requires downtime to avoid possible collisions in namespace_tags table.'

  disable_ddl_transaction!

  def up
    if Gitlab::Database.postgresql?
      execute <<-SQL
        UPDATE namespace_tags "nt"
        SET namespace_id = n.id
        FROM namespaces "n"
        WHERE n.owner_id is NOT NULL
        AND n.type IS NULL
        AND nt.namespace_id = n.owner_id
      SQL
    end
  end

  def down
    if Gitlab::Database.postgresql?
      execute <<-SQL
        UPDATE namespace_tags "nt"
        SET namespace_id = n.owner_id
        FROM namespaces "n"
        WHERE n.owner_id is NOT NULL
        AND n.type IS NULL
        AND nt.namespace_id = n.id
      SQL
    end
  end
end
