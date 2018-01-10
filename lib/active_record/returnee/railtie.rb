require 'rails/railtie'
require 'active_record'

module ActiveRecord
  class Returnee
    class Railtie < Rails::Railtie
      IGNORE_TABLES = [ActiveRecord::SchemaMigration.table_name, ActiveRecord::Base.internal_metadata_table_name]
      rake_tasks do
        namespace :db do
          desc "Generate migration files from Database"
          task :returnee do
            Rake::Task["db:load_config"].invoke
            dir = ActiveRecord::Tasks::DatabaseTasks.migrations_paths.first
            returnee = ActiveRecord::Returnee.new
            ActiveRecord::Base.connection.tables.reject{|name| IGNORE_TABLES.include?(name) }.each do |table_name|
              p returnee.to_create_table(table_name)

            end
          end
        end
      end
    end
  end
end
