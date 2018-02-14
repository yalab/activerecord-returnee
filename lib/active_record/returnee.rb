require "active_record/returnee/version"
require 'active_record/returnee/railtie'

module ActiveRecord
  class Returnee
    REG_ID = /_id\Z/
    REG_TYPE = /_type\Z/
    DEFAULT_COLUMNS = %w(id created_at updated_at).freeze
    def initialize(table_name)
      @table_name = table_name
      @connection = ActiveRecord::Base.connection
      @columns = @connection.columns(@table_name)
      @indexes = @connection.indexes(@table_name)
      @foreign_keys = @connection.foreign_keys(@table_name).each_with_object({}){|key, hash| hash[key.options[:column]] = key }
      @polymorphics = []
    end

    def to_create_table
      <<~EOS
      class Create#{@table_name.camelize} < ActiveRecord::Migration[5.1]
        def change#{extension}
          create_table :#{@table_name}#{id_type} do |t|
            #{columns}#{indexes}
          end
        end
      end
      EOS
    end

    def dependencies
      @columns
        .select{|column| references?(column) }
        .map{|column| column.name.gsub("_id", '').tableize.to_sym }
    end

    private
    def using_uuid?
      @using_uuid ||= begin
                        id = @columns.find{|column| column.name == "id" }
                        id.sql_type == "uuid"
                      end
    end

    def id_type
      if using_uuid?
        ", id: :uuid"
      end
    end

    def columns
      definitions = @columns.reject{|column| DEFAULT_COLUMNS.include?(column.name) }.map{|column|
        column(column)
      }.compact.join("\n      ")
      <<~EOS.chop
      #{definitions}

      #{timestamps}
      EOS
    end

    def indexes
      indexes = @indexes
                  .reject{|index| index.columns == ["id"] }
                  .reject{|index| @polymorphics.any?{|name| index.columns == ["#{name}_type", "#{name}_id"]} }
      indexes = indexes.map{|index| index(index) }.compact
      return if indexes.length < 1
      "\n      " + indexes.join("\n")
    end

    def index(index)
      columns = index.columns
      return if references?(columns)
      columns = if columns.length == 1
                  ":#{columns.first}"
                else
                  columns.map{|column| ":#{column}" }
                end
      columns = "[#{columns.join(", ")}]" if columns.is_a?(Array)
      "t.index #{columns}#{unique(index)}"
    end

    def unique(index)
      if index.unique
        ", unique: true"
      end
    end

    def column(column)
      if polymorphic?(column)
        "t.references :#{column.name.gsub(REG_TYPE, '')}, polymorphic: true, index: true"
      elsif references?(column)
        "t.references :#{column.name.gsub(REG_ID, '')}#{foreign_key(column)}"
      elsif @polymorphics.any?{|name| "#{name}_id" == column.name }
        nil
      else
        "t.#{column.type} :#{column.name}#{null(column)}#{default(column)}"
      end
    end

    def foreign_key(column)
      foreign_key = if @columns.find{|c| c.name == column.name }.sql_type == "uuid"
                      ", type: :uuid"
                    else
                      ""
                    end
      if @foreign_keys[column.name]
        "#{foreign_key}, foreign_key: true"
      end
    end

    def references?(column)
      return false if column.is_a?(Array) && column.length > 1
      column_name = column.is_a?(Array) ? column.first : column.name
      column_name =~ REG_ID && @indexes.find{|index| index.columns == [column_name] }
    end

    def polymorphic?(column)
      if column.name =~ REG_TYPE
        type_name = column.name
        @polymorphics << column.name.gsub(REG_TYPE, '')
        true
      end
    end

    def null(column)
      return if  column.null
      ", null: false"
    end

    def default(column)
      return unless column.default
      value = case column.type
              when :integer
                column.default
              when :boolean
                ["f", "false"].include?(column.default) ? 'false' : 'true'
              else
                %("#{column.default}")
              end
      ", default: #{value}"
    end

    def timestamps
      columns_hash = @columns.each_with_object({}){|column, hash| hash[column.name] = column }
      if columns_hash["created_at"] && columns_hash["updated_at"]
        "      t.timestamps"
      end
    end

    def extension
      return if @connection.adapter_name != "PostgreSQL"
      if using_uuid?
        "\n    enable_extension 'pgcrypto'"
      end
    end
  end
end
