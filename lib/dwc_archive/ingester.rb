# frozen_string_literal: true

class DarwinCore
  # This module abstracts information for reading csv file to be used
  # in several classes which need such functionality
  module Ingester
    attr_reader :data, :properties, :encoding, :fields_separator, :file_path, :fields, :line_separator,
                :quote_character, :ignore_headers

    def size
      @size ||= init_size
    end

    # TODO: Check if refactorable
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def read(batch_size = 10_000)
      DarwinCore.logger_write(@dwc.object_id, "Reading #{name} data")
      res = []
      errors = []
      args = define_csv_args
      min_size = @fields.map { |f| f[:index].to_i || 0 }.max + 1
      csv = CSV.new(File.open(@file_path), **args)
      csv.each_with_index do |r, i|
        next if @ignore_headers && i.zero?

        min_size > r.size ? errors << r : process_csv_row(res, errors, r)
        next if i.zero? || i % batch_size != 0

        DarwinCore.logger_write(@dwc.object_id,
                                format("Ingested %<records>s records from %<name>s",
                                       records: i, name: name))
        next unless block_given?

        yield [res, errors]
        res = []
        errors = []
      end
      yield [res, errors] if block_given?
      [res, errors]
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    private

    def define_csv_args
      args = { col_sep: @field_separator }
      args.merge!(quote_char: @quote_character&.empty? ? "\x00" : @quote_character)
      args.merge!(row_sep: @line_separator)
    end

    def name
      self.class.to_s.split("::")[-1].downcase
    end

    def process_csv_row(result, errors, row)
      str = row.join
      str = str.force_encoding("utf-8")
      if str.encoding.name == "UTF-8" && str.valid_encoding?
        result << row.map { |f| f.nil? ? nil : f.force_encoding("utf-8") }
      else
        errors << row
      end
    end

    def init_attributes
      @properties = @data[:attributes]
      init_encoding
      @field_separator = undump_attribute(@properties[:fieldsTerminatedBy], ",")
      @quote_character = undump_attribute(@properties[:fieldsEnclosedBy], "")
      @line_separator = undump_attribute(@properties[:linesTerminatedBy], "\n")

      @ignore_headers = @properties[:ignoreHeaderLines] &&
                        [1, true].include?(@properties[:ignoreHeaderLines])
      init_file_path
      init_fields
    end

    def init_encoding
      @encoding = @properties[:encoding] || "UTF-8"
      accepted_encoding = %w[utf-8 utf8 utf-16 utf16].
                          include?(@encoding.downcase)

      return if accepted_encoding

      raise DarwinCore::EncodingError,
            "No support for encodings other than utf-8 or utf-16 at the moment"
    end

    def init_file_path
      file = @data[:location] ||
             @data[:attributes][:location] ||
             @data[:files][:location]
      @file_path = File.join(@path, file)
      raise DarwinCore::FileNotFoundError, "No file data" unless @file_path
    end

    def init_fields
      @data[:field] = [data[:field]] if data[:field].class != Array
      @fields = @data[:field].map { |f| f[:attributes] }

      return unless @fields.empty?

      raise DarwinCore::InvalidArchiveError,
            "No data fields are found"
    end

    def undump_attribute(value, default)
      return unless value

      res = "\"#{value.gsub(/(?<!\\)"/, '\"')}\"".undump
      res.empty? ? default : res
    end

    def init_size
      `wc -l #{@file_path}`.match(/^\s*(\d+)\s/)[1].to_i
    end
  end
end
