require "json"
require "jsonpath"

module Embulk
  module Parser

    class JsonpathParserPlugin < ParserPlugin
      Plugin.register_parser("jsonpath", self)

      def self.transaction(config, &control)
        task = {
          schema: config.param("schema", :array),
          root: config.param("root", :string),
          stop_on_invalid_record: config.param("stop_on_invalid_record", :bool, default: false)
        }
        columns = task[:schema].each_with_index.map do |c, i|
          Column.new(i, c["name"], c["type"].to_sym)
        end
        yield(task, columns)
      end

      def run(file_input)
        root = JsonPath.new(@task["root"])
        schema = @task["schema"]
        stop_on_invalid_record = @task["stop_on_invalid_record"]
        while file = file_input.next_file
          json_text = file.read
          begin
            root.on(JSON.parse(json_text)).flatten.each do |e|
              @page_builder.add(make_record(schema, e))
            end
          rescue JSON::ParserError, DataParseError => e
            raise "Invalid record: '#{json_text}' (#{e})" if stop_on_invalid_record
            Embulk.logger.warn "Skipped record (#{e}): '#{json_text}'"
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
              if val.nil? || val.empty?
                nil
              else
                begin
                  Time.strptime(val, c["format"])
                rescue ArgumentError => e
                  raise DataParseError.new e
                end
              end
            else
              raise "Unsupported type #{type}"
          end
        end
      end

      def kind_of_boolean?(val)
        val.kind_of?(TrueClass) || val.kind_of?(FalseClass)
      end

      class DataParseError < StandardError ; end
    end
  end
end
