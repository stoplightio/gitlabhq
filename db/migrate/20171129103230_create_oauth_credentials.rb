# rubocop:disable all
class CreateOauthCredentials < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :oauth_credentials do |t|
      t.integer :source_id
      t.integer :user_id
      t.string :name
      t.string :secret
      t.string :route
      t.string :client_id
      t.string :client_secret
      t.string :access_token_url
      t.string :authorize_url
      t.string :scope

      t.index :source_id
      t.index :user_id
    end
  end
end
