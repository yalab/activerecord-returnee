require "active_record/returnee/version"

module ActiveRecord
  class Returnee
    REG_ID = /_id\Z/
    def to_create_table(table_name)
      @columns = ActiveRecord::Base.connection.columns(table_name)
      @indexes = ActiveRecord::Base.connection.indexes(table_name)
      @foreign_keys = ActiveRecord::Base.connection.foreign_keys(table_name).each_with_object({}){|key, hash| hash[key.options[:column]] = key }
      <<~EOS
      class Create#{table_name.capitalize} < ActiveRecord::Migration[5.1]
        def change
          create_table :#{table_name}#{id_type} do |t|
            #{columns}#{indexes}
          end
        end
      end
      EOS
    end

    private
    def id_type
      id = @columns.find{|column| column.name == "id" }
      if id.sql_type == "uuid"
        ", id: :uuid"
      end
    end

    def columns
      columns_hash = @columns.each_with_object({}){|column, hash| hash[column.name] = column }
      definitions = @columns.reject{|column| %w(id created_at updated_at).include?(column.name) }.map{|column|
        column(column)
      }.join("\n      ")
      <<~EOS.chop
      #{definitions}

      #{timestamp(columns_hash)}
      EOS
    end

    def indexes
      indexes = @indexes.reject{|index| index.columns == ["id"] }
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
      "t.index #{columns}#{unique(index)}"
    end

    def unique(index)
      if index.unique
        ", unique: true"
      end
    end

    def column(column)
      if references?(column)
        "t.references :#{column.name.gsub(REG_ID, '')}#{foreign_key(column)}"
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

    def references?(columns)
      raise if columns.is_a?(Array) && columns.length > 1
      column_name = columns.is_a?(Array) ? columns.first : columns.name
      column_name =~ REG_ID && @indexes.find{|index| index.columns = [column_name]}
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
                column.default == "f" ? 'false' : 'true'
              else
                %("#{column.default}")
              end
      ", default: #{value}"
    end

    def timestamp(columns_hash)
      if columns_hash["created_at"] && columns_hash["updated_at"]
        "      t.timestamps"
      end
    end
  end
end
