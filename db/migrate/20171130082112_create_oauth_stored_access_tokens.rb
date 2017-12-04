# rubocop:disable all
class CreateOauthStoredAccessTokens < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :oauth_stored_access_tokens do |t|
      t.integer :oauth_credentials_id
      t.integer :user_id
      t.string :name
      t.string :access_token, null: false
      t.string :scope
      t.string :token_type

      t.index :oauth_credentials_id
      t.index :user_id
    end
  end
end
