# 20180508162616_create_builds.rb

# rubocop:disable all
class CreateBuilds < ActiveRecord::Migration
  DOWNTIME = false

  def up
    create_table :builds do |t|
      t.integer :namespace_id
      t.integer :project_id
      t.integer :active_build_id
      t.string :status
      t.string :file_path
      t.string :comment
      t.string :commit
      t.string :branch
      t.datetime :ts, null: false
      t.jsonb :config, null: false, default: '{}'
    end

     add_index "builds", ["namespace_id"], name: "index_builds_on_namespace_id", using: :btree
  end

  def down
    drop_table :builds
  end
end