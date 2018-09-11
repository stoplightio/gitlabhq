class RemoveIndexOnFiles < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    if index_exists?(:project_files, [:branch, :path])
      remove_index :project_files, [:branch, :path]
    end
  end

  def down

  end
end
