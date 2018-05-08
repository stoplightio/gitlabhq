# 20180508162616_create_builds.rb

# rubocop:disable all
class CreateBuilds < ActiveRecord::Migration
  DOWNTIME = false

  def up
    create_table :builds do |t|
      t.integer :namespace_id
      t.integer :project_id
      t.string :status
      t.string :file_path
      t.string :comment
      t.string :commit
      t.string :branch
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.jsonb :config, null: false, default: '{}'
    end

     add_index "builds", ["namespace_id"], name: "index_builds_on_namespace_id", using: :btree
     add_index "builds", ["project_id"], name: "index_builds_on_project_id", using: :btree
  end

  def down
    drop_table :builds
  end
end