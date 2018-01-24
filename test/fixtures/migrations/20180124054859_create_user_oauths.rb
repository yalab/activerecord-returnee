class CreateUserOauths < ActiveRecord::Migration[5.1]
  def change
    create_table :user_oauths do |t|
      t.references :user, foreign_key: true
      t.string :provider
      t.string :uid

      t.timestamps
      t.index [:provider, :uid]
    end
  end
end
