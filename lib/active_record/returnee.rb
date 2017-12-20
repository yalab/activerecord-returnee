require "active_record/returnee/version"

module ActiveRecord
  module Returnee
    def self.to_create_table(table_name)
      <<~EOS
      class Create#{table_name.capitalize} < ActiveRecord::Migration[5.1]
        def change
          create_table :#{table_name}#{id_type(table_name)} do |t|
            #{columns(table_name)}#{indexes(table_name)}
          end
        end
      end
      EOS
    end

    private
    def self.id_type(table_name)
      id = ActiveRecord::Base.connection.columns(table_name).find{|column| column.name == "id" }
      if id.sql_type == "uuid"
        ", id: :uuid"
      end
    end

    def self.columns(table_name)
      columns = ActiveRecord::Base.connection.columns(table_name)
      columns_hash = columns.each_with_object({}){|column, hash| hash[column.name] = column }
      definitions = columns.reject{|column| %w(id created_at updated_at).include?(column.name) }.map{|column|
        "t.#{column.type} :#{column.name}#{null(column)}#{default(column)}"
      }.join("\n      ")
      <<~EOS.chop
      #{definitions}

      #{timestamp(columns_hash)}
      EOS
    end

    def self.indexes(table_name)
      indexes = ActiveRecord::Base.connection.indexes(table_name).reject{|index| index.columns == ["id"] }
      return if indexes.length < 1
      "\n      " + indexes.map{|index|
        "t.index #{index_name(index)}"
      }.join("\n")
    end

    def self.index_name(index)
      columns = index.columns
      columns = if columns.length == 1
                  ":#{columns.first}"
                else
                  columns.map{|column| ":#{column}" }
                end
      "#{columns}#{unique(index)}"
    end

    def self.unique(index)
      if index.unique
        ", unique: true"
      end
    end

    def self.null(column)
      return if  column.null
      ", null: false"
    end

    def self.default(column)
      return unless column.default
      value = case column.type
              when :integer
                column.default
              when :boolean
                column.default == "f" ? 'false' : 'true'
              else
                %("#{column.default}")
              end
      ", default: #{value}"
    end

    def self.timestamp(columns_hash)
      if columns_hash["created_at"] && columns_hash["updated_at"]
        "      t.timestamps"
      end
    end
  end
end
