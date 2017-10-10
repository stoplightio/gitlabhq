# rubocop:disable all
class CreateNamespaceTags < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :namespace_tags do |t|
      t.string :type
      t.string :name
      t.text :description
      t.string :primary_color
      t.boolean :public
      t.integer :namespace_id

      t.timestamps null: true
    end

     add_index "namespace_tags", ["namespace_id"], name: "index_namespace_tags_on_namespace_id", using: :btree
  end
end
