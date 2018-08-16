class CreateComments < ActiveRecord::Migration
  class Comment < ActiveRecord::Base
    enum parent_type: [:post, :commit, :pull_request, :build, :version, :release]
  end

  DOWNTIME = false

  def change
    create_table :comments do |t|
      t.integer :creator_id, null: false
      t.integer :parent_id, null: false
      t.string :parent_type, null: false
      t.string :body

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false

      t.index [:parent_type, :parent_id]
      t.index :created_at
    end
  end
end
