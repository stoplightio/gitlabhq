# 20190116182055_add_discovery_tables.rb

class AddDiscoveryTables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      execute <<-EOF
        DROP TYPE IF EXISTS node_type;
        CREATE TYPE node_type AS ENUM (
          'HttpServer',
          'HttpService',
          'Model',
          'Article',
          'HttpOperation'
        );
        
        DROP TYPE IF EXISTS node_edge_type;
        CREATE TYPE node_edge_type AS ENUM (
          'LINKS_TO',
          'REFERENCES',
          'SERVED_BY',
          'INCLUDES',
          'IS_PARENT'
        );
        
        DROP TYPE IF EXISTS node_history_change_type;
        CREATE TYPE node_history_change_type AS ENUM (
          'MAJOR',
          'MINOR',
          'PATCH'
        );
        
        DROP TYPE IF EXISTS provider;
        CREATE TYPE provider AS ENUM (
          'GITLAB'
        );
        
        DROP TYPE IF EXISTS branch_type;
        CREATE TYPE branch_type AS ENUM (
          'LIVE'
        );
        
        DROP TYPE IF EXISTS node_history_action;
        CREATE TYPE node_history_action AS ENUM (
          'ADDED',
          'MODIFIED',
          'REMOVED'
        );
        
        DROP TYPE IF EXISTS node_visibility;
        CREATE TYPE node_visibility AS ENUM (
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
        
        CREATE TABLE IF NOT EXISTS repos (
          id serial NOT NULL,
          project_id int4 NOT NULL,
          repo_location text NOT NULL,
          provider provider NOT NULL,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,
          CONSTRAINT repos_pkey PRIMARY KEY (id),
          CONSTRAINT repos_project_id_fkey FOREIGN KEY (project_id) REFERENCES projects(id)
        );
        CREATE UNIQUE INDEX IF NOT EXISTS repos_repo_location_idx ON repos USING btree (repo_location);
        
        CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    repos FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();
        
        CREATE TABLE IF NOT EXISTS vcs_users (
          id serial NOT NULL,
          username text NOT NULL,
          provider provider NOT NULL,
          user_id int4,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,	
          CONSTRAINT vcs_users_pkey PRIMARY KEY (id),
          CONSTRAINT vcs_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id)
        );
        CREATE UNIQUE INDEX IF NOT EXISTS vcs_users_username_provider_idx ON vcs_users USING btree (username, provider);
        
        CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    vcs_users FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();
        
        CREATE TABLE IF NOT EXISTS commits (
          commit_sha text NOT NULL,
          message text NOT NULL,
          author_vcs_user_id int4 NOT NULL,
          committer_vcs_user_id int4 NOT NULL,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,
          CONSTRAINT commits_pkey PRIMARY KEY (commit_sha),
          CONSTRAINT commits_author_vcs_user_id_fkey FOREIGN KEY (author_vcs_user_id) REFERENCES vcs_users(id),
          CONSTRAINT commits_committer_vcs_user_id_fkey FOREIGN KEY (committer_vcs_user_id) REFERENCES vcs_users(id)
        );
        
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
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,
          CONSTRAINT branches_pkey PRIMARY KEY (id),
          CONSTRAINT branches_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repos(id)
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
          visibility node_visibility NOT NULL,
          repo_id int4 NOT NULL,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,
          CONSTRAINT nodes_pkey PRIMARY KEY (id),
          CONSTRAINT nodes_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repos(id)
        );
        CREATE UNIQUE INDEX IF NOT EXISTS nodes_id_hash_repo_id_idx ON nodes USING btree (id_hash, repo_id);
        
        CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    nodes FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();
        
        CREATE TABLE IF NOT EXISTS commit_branches (
          id serial NOT NULL,
          commit_sha text NOT NULL,
          branch_id int4 NOT NULL,
          committed_at timestamp NOT NULL,
          analyzer_status analyzer_status NOT NULL,
          analyzer_job_id text,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL, 
          CONSTRAINT commit_branches_pkey PRIMARY KEY (id),
          CONSTRAINT commit_branches_branch_id FOREIGN KEY (branch_id) REFERENCES branches(id),
          CONSTRAINT commit_branches_commit_sha FOREIGN KEY (commit_sha) REFERENCES commits(commit_sha)
        );
        CREATE UNIQUE INDEX IF NOT EXISTS commit_branches_commit_sha_branch_id_idx ON commit_branches USING btree (commit_sha, branch_id);

        CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    commit_branches FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();
        
        CREATE TABLE IF NOT EXISTS node_history (
          id serial NOT NULL,
          node_id int4 NOT NULL,
          "data" jsonb NOT NULL,
          data_hash text NOT NULL,
          change_type node_history_change_type NOT NULL,
          action node_history_action NOT NULL,
          commit_sha text NULL,
          file_path text NOT NULL,	
          shared_version text NULL,
          created_at timestamp NULL DEFAULT now(),
          deleted_at timestamp NULL,	
          CONSTRAINT node_history_pkey PRIMARY KEY (id),
          CONSTRAINT node_history_commit_sha_fkey FOREIGN KEY (commit_sha) REFERENCES commits(commit_sha),
          CONSTRAINT node_history_node_id_fkey FOREIGN KEY (node_id) REFERENCES nodes(id)
        );
        CREATE UNIQUE INDEX IF NOT EXISTS node_history_node_id_commit_sha_idx ON node_history USING btree (node_id, commit_sha);
        
        CREATE OR REPLACE FUNCTION public.trigger_set_node_history_deleted_at()
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
                    node_history FOR EACH ROW EXECUTE PROCEDURE trigger_set_node_history_deleted_at();
        
        
        CREATE TABLE IF NOT EXISTS node_edges (
          id serial NOT NULL,
          from_node_id int4 NOT NULL,
          "type" node_edge_type NOT NULL,
          to_node_id int4 NOT NULL,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL,
          CONSTRAINT node_relationships_pkey PRIMARY KEY (id),
          CONSTRAINT node_relationships_from_id_fkey FOREIGN KEY (from_node_id) REFERENCES nodes(id),
          CONSTRAINT node_relationships_to_id_fkey FOREIGN KEY (to_node_id) REFERENCES nodes(id)
        );
        
        CREATE
            TRIGGER trigger_set_timestamp BEFORE INSERT
                OR UPDATE
                    ON
                    node_edges FOR EACH ROW EXECUTE PROCEDURE trigger_set_timestamp();
        
        CREATE TABLE IF NOT EXISTS node_history_validations (
          id serial NOT NULL,
          node_history_id int4 NOT NULL,
          data jsonb NOT NULL,
          created_at timestamp NOT NULL DEFAULT now(),
          CONSTRAINT node_history_validations_pkey PRIMARY KEY (id),
          CONSTRAINT node_history_validations_node_history_id_fkey FOREIGN KEY (node_history_id) REFERENCES node_history(id)
        );
        CREATE UNIQUE INDEX IF NOT EXISTS node_history_validations_node_hist_id_data_idx ON node_history_validations USING btree (node_history_id, data);
      EOF
    end
  end

  def down
    if Gitlab::Database.postgresql?
      execute <<-EOF
        DROP TABLE IF EXISTS node_history_validations;

        DROP TABLE IF EXISTS node_edges;

        DROP TABLE IF EXISTS node_history;

        DROP FUNCTION IF EXISTS trigger_set_node_history_deleted_at();

        DROP TABLE IF EXISTS commit_branches;

        DROP TABLE IF EXISTS nodes;

        DROP TABLE IF EXISTS branches;

        DROP TABLE IF EXISTS commits;

        DROP TABLE IF EXISTS vcs_users;

        DROP TABLE IF EXISTS repos;

        DROP TYPE IF EXISTS analyzer_status;

        DROP TYPE IF EXISTS node_visibility;

        DROP TYPE IF EXISTS node_history_action;

        DROP TYPE IF EXISTS branch_type;

        DROP TYPE IF EXISTS provider;

        DROP TYPE IF EXISTS node_history_change_type;

        DROP TYPE IF EXISTS node_edge_type;

        DROP TYPE IF EXISTS node_type;
      EOF
    end
  end
end
