require "test_helper"

class ActiveRecord::ReturneeTest < Minitest::Test
  def setup
    ActiveRecord::Base.establish_connection(
      :adapter => "postgresql",
      :database  => "returnee_test"
    )
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Migrator.migrate(File.expand_path("../../fixtures/migrations/", __FILE__)) do |migration|
      true
    end
    ActiveRecord::Base.clear_cache!
    @returnee = ActiveRecord::Returnee.new
  end

  def test_that_it_has_a_version_number
    refute_nil ::ActiveRecord::Returnee::VERSION
  end

  def test_create_users
    assert_equal <<~CREATE_TABLE, @returnee.to_create_table("users")
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
    assert_equal <<~CREATE_TABLE, @returnee.to_create_table("groups")
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

  def test_create_members
    assert_equal <<~CREATE_TABLE, @returnee.to_create_table("members")
      class CreateMembers < ActiveRecord::Migration[5.1]
        def change
          create_table :members do |t|
            t.references :user, foreign_key: true
            t.references :group, type: :uuid, foreign_key: true

            t.timestamps
          end
        end
      end
    CREATE_TABLE
  end
end
