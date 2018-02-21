class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.text :address
      t.integer :age, default: 0
      t.float :weight
      t.decimal :height
      t.datetime :confirmed_at
      t.datetime :deleted_at
      t.time :last_login
      t.date :birthday
      t.binary :avatar
      t.boolean :email_receive, default: false
      t.integer :source_type

      t.timestamps
      t.index :email, unique: true
    end
  end
end
