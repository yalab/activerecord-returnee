class CreateUserOauths < ActiveRecord::Migration[5.1]
  def change
    create_table :user_oauths do |t|
      t.references :user, foreign_key: true
      t.string :provider
      t.string :uid
      t.index [:provider, :uid]

      t.timestamps
    end
  end
end
