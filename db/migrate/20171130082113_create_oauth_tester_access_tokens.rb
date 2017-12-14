# rubocop:disable all
class CreateOauthTesterAccessTokens < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :oauth_tester_access_tokens do |t|
      t.integer :user_id
      t.integer :project_id
      t.integer :namespace_id
      t.boolean :shared
      t.string :name
      t.string :access_token
      t.string :scope
      t.string :token_type
      t.string :description

      t.index :user_id
      t.index :project_id
      t.index :namespace_id
    end
  end
end
