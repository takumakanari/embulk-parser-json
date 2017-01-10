require "json"
require "jsonpath"

module Embulk
  module Parser

    class JsonpathParserPlugin < ParserPlugin
      Plugin.register_parser("jsonpath", self)

      def self.transaction(config, &control)
        task = {
          :schema => config.param("schema", :array),
          :root => config.param("root", :string)
        }
        columns = task[:schema].each_with_index.map do |c, i|
          Column.new(i, c["name"], c["type"].to_sym)
        end
        yield(task, columns)
      end

      def run(file_input)
        root = JsonPath.new(@task["root"])
        schema = @task["schema"]
        while file = file_input.next_file
          root.on(JSON.parse(file.read)).flatten.each do |e|
            @page_builder.add(make_record(schema, e))
          end
        end
        @page_builder.finish
      end

      private
      def make_record(schema, e)
        schema.map do |c|
          name = c["name"]
          path = c["path"]

          val = path.nil? ? e[name] : JsonPath.on(e, path).first
          type = c["type"]
          case type
            when "string"
              val
            when "long"
              val.to_i
            when "double"
              val.to_f
            when "json"
              val
            when "boolean"
              if kind_of_boolean?(val)
                val
              elsif val.nil? || val.empty?
                nil
              elsif val.kind_of?(String)
                ["yes", "true", "1"].include?(val.downcase)
              elsif val.kind_of?(Numeric)
                !val.zero?
              else
                !!val
              end
            when "timestamp"
              val.nil? || val.empty? ? nil : Time.strptime(val, c["format"])
            else
              raise "Unsupported type #{type}"
          end
        end
      end

      def kind_of_boolean?(val)
        val.kind_of?(TrueClass) || val.kind_of?(FalseClass)
      end
    end
  end
end
