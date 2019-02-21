# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDiscoverySearchTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      execute <<-EOF
        CREATE TABLE IF NOT EXISTS node_search (
            id serial NOT NULL,
            node_version_id int4 NOT NULL,
            node_id int4 NOT NULL,
            node_type text NOT NULL,
            project_id int4 NOT NULL,
            org_id int4 NOT NULL,
            document tsvector,
            created_at timestamp NOT NULL,
            updated_at timestamp NOT NULL,
            CONSTRAINT node_search_pkey PRIMARY KEY (id),
            CONSTRAINT node_search_node_version_id FOREIGN KEY (node_version_id) REFERENCES node_versions(id) ON DELETE CASCADE,
            CONSTRAINT node_search_node_id FOREIGN KEY (node_id) REFERENCES nodes(id) ON DELETE CASCADE,
            CONSTRAINT node_project_id FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
            CONSTRAINT node_org_id FOREIGN KEY (org_id) REFERENCES namespaces(id) ON DELETE CASCADE
          );

          CREATE UNIQUE INDEX IF NOT EXISTS node_search_node_id_node_version_id_idx ON node_search USING btree (node_id, node_version_id);
          CREATE INDEX node_search_document_idx ON node_search USING gin(document);

          CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    node_search FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();
      EOF
    end
  end

  def down
    if Gitlab::Database.postgresql?
      execute <<-EOF
        DROP TABLE IF EXISTS node_search;
      EOF
    end
  end
end
