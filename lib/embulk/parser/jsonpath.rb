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
        rootPath = JsonPath.new(@task["root"])
        schema = @task["schema"]
        while file = file_input.next_file
          rootPath.on(file.read).flatten.each do |e|
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
          val = path.nil? ? e[name] : find_by_path(e, path)

          v = val.nil? ? "" : val
          type = c["type"]
          case type
            when "string"
              v
            when "long"
              v.to_i
            when "double"
              v.to_f
            when "boolean"
              if v.nil?
                nil
              elsif v.kind_of?(String)
                ["yes", "true", "1"].include?(v.downcase)
              elsif v.kind_of?(Numeric)
                !v.zero?
              else
                !!v
              end
            when "timestamp"
              v.empty? ? nil : Time.strptime(v, c["format"])
            else
              raise "Unsupported type #{type}"
          end
        end
      end

      def find_by_path(e, path)
        JsonPath.on(e, path).first
      end
    end

  end
end
