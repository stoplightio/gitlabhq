# rubocop:disable all
class CreateOauthCredentials < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :oauth_credentials do |t|
      t.integer :user_id
      t.string :token_name
      t.string :secret
      t.string :route
      t.string :client_id
      t.string :client_secret
      t.string :access_token_url
      t.string :authorize_url
      t.string :scope

      t.timestamps null: true
    end

     add_index "oauth_credentials", ["user_id"], name: "index_oauth_credentials_on_user_id", using: :btree, unique: true
  end
end
