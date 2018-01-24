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
    assert_equal fixture_path(:users).read, @returnee.to_create_table("users")
  end

  def test_create_groups
    assert_equal fixture_path(:groups).read, @returnee.to_create_table("groups")
  end

  def test_create_members
    assert_equal fixture_path(:members).read, @returnee.to_create_table("members")
  end

  def test_create_user_oauths
    assert_equal fixture_path(:user_oauths).read, @returnee.to_create_table("user_oauths")
  end

  private
  def fixture_path(name)
    Pathname.new Dir.glob(File.expand_path("../../fixtures/migrations/*#{name}*", __FILE__)).first
  end
end
