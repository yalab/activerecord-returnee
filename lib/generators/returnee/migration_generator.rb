require 'active_record/returnee'

module Returnee
  module Generators
    class MigrationGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)
      INTERNAL_TABLES = %w(schema_migrations ar_internal_metadata).freeze

      def create_migration_file
        returnee = ::ActiveRecord::Returnee.new
        dir = Rails.root.join("db/migrate")
        ActiveRecord::Base.connection.tables.each.with_index do |name, i|
          next if INTERNAL_TABLES.include?(name)
          number = ActiveRecord::Migration.next_migration_number(0)
          number = number.to_i + i
          fname = "#{number}_create_#{name}.rb"
          File.open(dir.join(fname), "w") do |f|
            f.puts returnee.to_create_table(name)
          end
          ActiveRecord::Base.connection.execute "INSERT INTO schema_migrations VALUES (#{number})"
        end
      end
    end
  end
end
