# 20181012180851_add_constraints_on_project_id.rb

# rubocop:disable all
class AddConstraintsOnProjectId < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  def up
    if Gitlab::Database.postgresql?
      execute %q{
        ALTER TABLE "docs"
          ADD CONSTRAINT "docs_project_id_fkey"
          FOREIGN KEY ("project_id")
          REFERENCES "projects" ("id")
          ON DELETE CASCADE
          NOT VALID;
      }

      execute %q{
        ALTER TABLE "comments"
          ADD CONSTRAINT "comments_parent_id_fkey"
          FOREIGN KEY ("parent_id")
          REFERENCES "posts" ("id")
          ON DELETE CASCADE
          NOT VALID;
      }

      execute %q{
        ALTER TABLE "projects"
          ADD CONSTRAINT "project_namespace_id_fkey"
          FOREIGN KEY ("namespace_id")
          REFERENCES "namespaces" ("id")
          ON DELETE CASCADE
          NOT VALID;
      }
    end
  end

  def down
    execute %q{
      ALTER TABLE "docs" DROP CONSTRAINT "docs_project_id_fkey"
    }

    execute %q{
      ALTER TABLE "comments" DROP CONSTRAINT "comments_parent_id_fkey"
    }

    execute %q{
      ALTER TABLE "projects" DROP CONSTRAINT "project_namespace_id_fkey"
    }
  end

end
