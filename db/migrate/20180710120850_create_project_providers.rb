class CreateProjectProviders < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :project_providers do |t|
      t.integer :project_id, null: false
      t.string :name, null: false
      t.string :namespace, null: true
      t.string :repo, null: true 
      t.string :host, null: true
      t.string :uri, null: true

      t.timestamps null: true

      t.foreign_key :projects, column: :project_id, on_delete: :cascade

      t.index :project_id, unique: true
    end
  end
end
