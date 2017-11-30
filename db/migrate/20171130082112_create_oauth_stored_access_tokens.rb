# rubocop:disable all
class CreateOauthStoredAccessTokens < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :oauth_stored_access_tokens do |t|
      t.integer :user_id, null: false
      t.string :name
      t.string :access_token, null: false
      t.string :scope
      t.string :token_type

      t.timestamps null: true
    end

     add_index "oauth_stored_access_tokens", ["user_id"], name: "index_oauth_stored_access_tokens_on_user_id", using: :btree
  end
end
