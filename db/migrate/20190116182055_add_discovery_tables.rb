# 20190116182055_add_discovery_tables.rb

class AddDiscoveryTables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      execute <<-EOF
        DROP TYPE IF EXISTS node_type;
        CREATE TYPE node_type AS ENUM (
          'http_server',
          'http_service',
          'json_schema',
          'article',
          'http_operation'
        );

        DROP TYPE IF EXISTS node_version_edge_type;
        CREATE TYPE node_version_edge_type AS ENUM (
          'LINKS_TO',
          'REFERENCES',
          'SERVED_BY',
          'INCLUDES',
          'IS_PARENT'
        );

        DROP TYPE IF EXISTS semver;
        CREATE TYPE semver AS ENUM (
          'MAJOR',
          'MINOR',
          'PATCH',
          'UNKNOWN'
        );

        DROP TYPE IF EXISTS provider;
        CREATE TYPE provider AS ENUM (
          'GITLAB'
        );

        DROP TYPE IF EXISTS branch_type;
        CREATE TYPE branch_type AS ENUM (
          'LIVE'
        );

        DROP TYPE IF EXISTS node_version_history_action;
        CREATE TYPE node_version_history_action AS ENUM (
          'ADDED',
          'MODIFIED',
          'REMOVED'
        );

        DROP TYPE IF EXISTS visibility;
        CREATE TYPE visibility AS ENUM (
          'INTERNAL',
          'PRIVATE',
          'PUBLIC'
        );

        DROP TYPE IF EXISTS analyzer_status;
        CREATE TYPE analyzer_status AS ENUM (
          'RUNNING',
          'COMPLETED',
          'FAILED'
        );

        DROP TYPE IF EXISTS validation_severity;
        CREATE TYPE validation_severity AS ENUM (
          'info',
          'warn',
          'error'
        );

        DROP TYPE IF EXISTS change_code;
        CREATE TYPE change_code AS ENUM (
          'UNKNOWN'
        );

        CREATE TABLE IF NOT EXISTS repos (
          id serial NOT NULL,
          project_id int4 NOT NULL,
          repo_location text NOT NULL,
          provider provider NOT NULL,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,
          CONSTRAINT repos_pkey PRIMARY KEY (id),
          CONSTRAINT repos_project_id_fkey FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
        );
        CREATE UNIQUE INDEX IF NOT EXISTS repos_repo_location_idx ON repos USING btree (repo_location);

        CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    repos FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();

        CREATE TABLE IF NOT EXISTS vcs_users (
          id serial NOT NULL,
          email text NOT NULL,
          provider provider NOT NULL,
          user_id int4,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,
          CONSTRAINT vcs_users_pkey PRIMARY KEY (id),
          CONSTRAINT vcs_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        );
        CREATE UNIQUE INDEX IF NOT EXISTS vcs_users_email_provider_idx ON vcs_users USING btree (email, provider);

        CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    vcs_users FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();

        CREATE TABLE IF NOT EXISTS commits (
          id serial NOT NULL,
          commit_sha text NOT NULL,
          message text NOT NULL,
          author_vcs_user_id int4 NOT NULL,
          committer_vcs_user_id int4 NOT NULL,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,
          CONSTRAINT commits_pkey PRIMARY KEY (id),
          CONSTRAINT commits_author_vcs_user_id_fkey FOREIGN KEY (author_vcs_user_id) REFERENCES vcs_users(id),
          CONSTRAINT commits_committer_vcs_user_id_fkey FOREIGN KEY (committer_vcs_user_id) REFERENCES vcs_users(id)
        );
        CREATE UNIQUE INDEX IF NOT EXISTS commits_commit_sha_idx ON commits USING btree (commit_sha);

        CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    commits FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();

        CREATE TABLE IF NOT EXISTS branches (
          id serial NOT NULL,
          branch_name text NOT NULL,
          branch_type branch_type NULL,
          repo_id int4 NULL,
          project_id int4 NULL,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,
          CONSTRAINT branches_pkey PRIMARY KEY (id),
          CONSTRAINT branches_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repos(id) ON DELETE CASCADE,
          CONSTRAINT branches_project_id_fkey FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
        );
        CREATE UNIQUE INDEX IF NOT EXISTS branches_branch_name_repo_id_idx ON branches USING btree (branch_name, repo_id);

        CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    branches FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();

        CREATE TABLE IF NOT EXISTS nodes (
          id serial NOT NULL,
          type node_type NOT NULL,
          id_hash text NOT NULL,
          repo_id int4 NOT NULL,
          project_id int4 NULL,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,
          CONSTRAINT nodes_pkey PRIMARY KEY (id),
          CONSTRAINT nodes_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repos(id) ON DELETE CASCADE,
          CONSTRAINT nodes_project_id_fkey FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
        );
        CREATE UNIQUE INDEX IF NOT EXISTS nodes_id_hash_repo_id_idx ON nodes USING btree (id_hash, repo_id);

        CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    nodes FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();

        CREATE TABLE IF NOT EXISTS commit_branches (
          id serial NOT NULL,
          commit_id int4 NOT NULL,
          branch_id int4 NOT NULL,
          committed_at timestamp NOT NULL,
          analyzer_status analyzer_status NOT NULL,
          analyzer_job_id text,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,
          CONSTRAINT commit_branches_pkey PRIMARY KEY (id),
          CONSTRAINT commit_branches_branch_id FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE,
          CONSTRAINT commit_branches_commit_id FOREIGN KEY (commit_id) REFERENCES commits(id) ON DELETE CASCADE
        );
        CREATE UNIQUE INDEX IF NOT EXISTS commit_branches_commit_id_branch_id_idx ON commit_branches USING btree (commit_id, branch_id);

        CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    commit_branches FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();

        CREATE TABLE IF NOT EXISTS node_versions (
          id serial NOT NULL,
          node_id int4 NOT NULL,
          version text NOT NULL,
          visibility visibility NOT NULL,
          "data" jsonb NOT NULL,
          data_hash text NOT NULL,
          file_path text NOT NULL,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,
          CONSTRAINT node_versions_pkey PRIMARY KEY (id),
          CONSTRAINT node_versions_node_id_fkey FOREIGN KEY (node_id) REFERENCES nodes(id) ON DELETE CASCADE
        );
        CREATE UNIQUE INDEX IF NOT EXISTS node_id_version_idx ON node_versions USING btree (node_id, version);

        CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    node_versions FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();

        CREATE TABLE IF NOT EXISTS node_version_history (
          id serial NOT NULL,
          node_version_id int4 NOT NULL,
          commit_id int4 NOT NULL,
          action node_version_history_action NOT NULL,
          semver semver NOT NULL,
          created_at timestamp NULL DEFAULT now(),
          deleted_at timestamp NULL,
          CONSTRAINT node_version_history_pkey PRIMARY KEY (id),
          CONSTRAINT node_version_history_commit_id_fkey FOREIGN KEY (commit_id) REFERENCES commits(id) ON DELETE CASCADE,
          CONSTRAINT node_version_history_node_version_id_fkey FOREIGN KEY (node_version_id) REFERENCES node_versions(id) ON DELETE CASCADE
        );
        CREATE UNIQUE INDEX IF NOT EXISTS node_version_history_node_version_id_commit_id_idx ON node_version_history USING btree (node_version_id, commit_id);

        CREATE OR REPLACE FUNCTION public.trigger_set_node_version_history_deleted_at()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $function$
                    BEGIN
                      IF NEW.action = 'REMOVED' then
                        NEW.deleted_at = NOW();
                      END IF;

                      RETURN NEW;
                    END;
                    $function$
        ;

        CREATE
            TRIGGER trigger_set_deleted_at BEFORE INSERT
                OR UPDATE
                    ON
                    node_version_history FOR EACH ROW EXECUTE PROCEDURE trigger_set_node_version_history_deleted_at();


        CREATE TABLE IF NOT EXISTS node_version_edges (
          id serial NOT NULL,
          from_node_version_id int4 NOT NULL,
          "type" node_version_edge_type NOT NULL,
          to_node_version_id int4 NOT NULL,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,
          CONSTRAINT node_version_edges_pkey PRIMARY KEY (id),
          CONSTRAINT node_version_edges_from_id_fkey FOREIGN KEY (from_node_version_id) REFERENCES node_versions(id) ON DELETE CASCADE,
          CONSTRAINT node_version_edges_to_id_fkey FOREIGN KEY (to_node_version_id) REFERENCES node_versions(id) ON DELETE CASCADE
        );

        CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    node_version_edges FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();

        CREATE TABLE IF NOT EXISTS node_version_history_validations (
          id serial NOT NULL,
          node_version_history_id int4 NOT NULL,
          severity validation_severity NOT NULL,
          data jsonb NOT NULL,
          created_at timestamp NOT NULL DEFAULT now(),
          CONSTRAINT node_version_history_validations_pkey PRIMARY KEY (id),
          CONSTRAINT node_version_history_validations_node_version_history_id_fkey FOREIGN KEY (node_version_history_id) REFERENCES node_version_history(id) ON DELETE CASCADE
        );
        CREATE UNIQUE INDEX IF NOT EXISTS node_version_history_validations_node_ver_hist_id_data_idx ON node_version_history_validations USING btree (node_version_history_id, data);

        CREATE TABLE IF NOT EXISTS node_version_history_changelog (
          id serial NOT NULL,
          node_version_history_id int4 NOT NULL,
          semver text NOT NULL,
          code text NOT NULL,
          operation text NOT NULL,
          context text NOT NULL,
          data jsonb NOT NULL,
          message text NOT NULL,
          created_at timestamp NOT NULL DEFAULT now(),
          CONSTRAINT node_version_history_changelog_pkey PRIMARY KEY (id),
          CONSTRAINT node_version_history_changelog_node_version_history_id_fkey FOREIGN KEY (node_version_history_id) REFERENCES node_version_history(id) ON DELETE CASCADE
        );
      EOF
    end
  end

  def down
    if Gitlab::Database.postgresql?
      execute <<-EOF
        DROP TABLE IF EXISTS node_version_history_changelog;

        DROP TABLE IF EXISTS node_version_history_validations;

        DROP TABLE IF EXISTS node_version_edges;

        DROP TABLE IF EXISTS node_version_history;

        DROP FUNCTION IF EXISTS trigger_set_node_version_history_deleted_at();

        DROP TABLE IF EXISTS node_version_history;

        DROP TABLE IF EXISTS node_versions;

        DROP TABLE IF EXISTS commit_branches;

        DROP TABLE IF EXISTS nodes;

        DROP TABLE IF EXISTS branches;

        DROP TABLE IF EXISTS commits;

        DROP TABLE IF EXISTS vcs_users;

        DROP TABLE IF EXISTS repos;

        DROP TYPE IF EXISTS change_code;

        DROP TYPE IF EXISTS validation_severity;

        DROP TYPE IF EXISTS analyzer_status;

        DROP TYPE IF EXISTS visibility;

        DROP TYPE IF EXISTS node_version_history_action;

        DROP TYPE IF EXISTS branch_type;

        DROP TYPE IF EXISTS provider;

        DROP TYPE IF EXISTS semver;

        DROP TYPE IF EXISTS node_version_edge_type;

        DROP TYPE IF EXISTS node_type;
      EOF
    end
  end
end
