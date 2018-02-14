require 'rails/railtie'
require 'active_record'
require 'rails/generators'
require 'rails/generators/active_record'

module ActiveRecord
  class Returnee
    class Railtie < Rails::Railtie
      IGNORE_TABLES = [ActiveRecord::SchemaMigration.table_name, ActiveRecord::Base.internal_metadata_table_name]
      rake_tasks do
        namespace :db do
          desc "Generate migration files from Database"
          task :returnee => :construct_dependency_tree do
            connection = ActiveRecord::Base.connection

            dir = Pathname.new(ActiveRecord::Tasks::DatabaseTasks.migrations_paths.first)
            finished = []
            number = 0
            connection.execute("DELETE FROM schema_migrations")
            create_migration = ->(table_name) {
              migration_number = (Time.now.utc.strftime("%Y%m%d%H%M") + "%02d") % number
              number += 1
              connection.execute("INSERT INTO schema_migrations (version) VALUES ('#{migration_number}')")
              fname = if table_name == "active_storage_blobs"
                        table_name = "active_storage"
                        "#{migration_number}_create_active_storage_tables.active_storagecreate_active_storage.rb"
                      else
                        "#{migration_number}_create_#{table_name}.rb"
                      end
              File.open(dir.join(fname), "w") do |f|
                f.puts ActiveRecord::Returnee.new(table_name).to_create_table
              end
              finished << table_name.to_sym
            }
            @dependency_tree.delete("active_storage_attachments")
            @dependency_tree.delete(nil).each do |table_name|
              create_migration.call(table_name)
            end
            while @dependency_tree.keys.length > 0
              @dependency_tree.each do |table_name, depends|
                if depends.all?{|_table_name| finished.include?(_table_name)  }
                  create_migration.call(table_name)
                  @dependency_tree.delete(table_name)
                end
              end
            end
          end

          task :construct_dependency_tree => :"db:load_config" do
            @dependency_tree = {}
            table_names = ActiveRecord::Base.connection.tables.reject{|name| IGNORE_TABLES.include?(name) }
            table_names.each do |table_name|
              dependencies = ActiveRecord::Returnee.new(table_name).dependencies
              if dependencies.length < 1
                @dependency_tree[nil] ||= []
                @dependency_tree[nil] << table_name
              else
                @dependency_tree[table_name] = dependencies
              end
            end
          end
        end
      end
    end
  end
end
