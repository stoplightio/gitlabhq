class CreatePosts < ActiveRecord::Migration
  class Post < ActiveRecord::Base
    enum state: [:open, :closed]
    enum type: [:discussion, :issue]
  end

  DOWNTIME = false

  def change
    create_table :posts do |t|
      t.integer :iid, null: false
      t.integer :project_id, null: false
      t.integer :creator_id, null: false
      t.integer :file_id

      t.string :state, null: false, default: 'open'
      t.string :type, null: false
      t.string :title
      t.string :body
      t.string :file_loc

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false

      t.foreign_key :projects, column: :project_id, on_delete: :cascade
      t.foreign_key :users, column: :creator_id, on_delete: :cascade
      # TODO: uncomment this after files migrations will be implemented
      # t.foreign_key :files, column: :file_id, on_delete: :cascade
      
      t.index :project_id
      t.index :file_id
      t.index :creator_id
      t.index :state
      t.index :created_at
    end
  end
end
