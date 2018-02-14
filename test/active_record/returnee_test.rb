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
  end

  def test_that_it_has_a_version_number
    refute_nil ::ActiveRecord::Returnee::VERSION
  end

  def test_create_users
    assert_equal fixture_path(:users).read, ActiveRecord::Returnee.new("users").to_create_table
  end

  def test_create_groups
    assert_equal fixture_path(:groups).read, ActiveRecord::Returnee.new("groups").to_create_table
  end

  def test_create_members
    assert_equal fixture_path(:members).read, ActiveRecord::Returnee.new("members").to_create_table
  end

  def test_create_user_oauths
    assert_equal fixture_path(:user_oauths).read, ActiveRecord::Returnee.new("user_oauths").to_create_table
  end

  def test_create_user_pictures
    assert_equal fixture_path(:pictures).read, ActiveRecord::Returnee.new("pictures").to_create_table
  end

  def test_create_user_pictures
    assert_equal fixture_path(:active_storage).read, ActiveRecord::Returnee.new("active_storage").to_create_table
  end

  def test_members_dependencies
    assert_equal [:users, :groups], ActiveRecord::Returnee.new("members").dependencies
  end

  private
  def fixture_path(name)
    Pathname.new Dir.glob(File.expand_path("../../fixtures/migrations/*#{name}*", __FILE__)).first
  end
end
