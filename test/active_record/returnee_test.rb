require "test_helper"

class ActiveRecord::ReturneeTest < Minitest::Test
  def setup
    ActiveRecord::Base.establish_connection(
      :adapter => "sqlite3",
      :database  => ":memory:"
    )
    [<<~SQL0,
      CREATE TABLE "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "email" varchar NOT NULL, "address" text, "age" integer DEFAULT 0, "weight" float, "height" decimal, "confirmed_at" datetime, "deleted_at" datetime, "last_login" time, "birthday" date, "avatar" blob, "email_receive" boolean DEFAULT 'f', "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
     SQL0
     <<~SQL1,
       CREATE UNIQUE INDEX "index_users_on_email" ON "users" ("email");
     SQL1
     <<~SQL2,
       CREATE TABLE "groups" ("id" uuid NOT NULL PRIMARY KEY, "name" varchar, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
     SQL2
    ].each do |sql|
      ActiveRecord::Base.connection.execute sql
    end
  end

  def test_that_it_has_a_version_number
    refute_nil ::ActiveRecord::Returnee::VERSION
  end

  def test_create_users
    assert_equal <<~CREATE_TABLE, ActiveRecord::Returnee.to_create_table("users")
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

            t.timestamps
            t.index :email, unique: true
          end
        end
      end
    CREATE_TABLE
  end

  def test_create_groups
    assert_equal <<~CREATE_TABLE, ActiveRecord::Returnee.to_create_table("groups")
      class CreateGroups < ActiveRecord::Migration[5.1]
        def change
          create_table :groups, id: :uuid do |t|
            t.string :name

            t.timestamps
          end
        end
      end
    CREATE_TABLE
  end
end
