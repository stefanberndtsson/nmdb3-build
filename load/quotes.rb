require 'movies'

module Nmdb
  class Quotes
    attr_reader :missed

    IGNORE_BEFORE="QUOTES LIST"
    IGNORE_AFTER=1
    DONE_AT="-------------------------------------"

    def initialize(input_file, quotes_file, quote_data_file)
      @quotes_output = File.open(quotes_file, "w")
      @quote_data_output = File.open(quote_data_file, "w")
      @missed = 0
      @max_id = 0
      @max_data_id = 0
      ignoring = true
      waiting = nil
      File.open(input_file).each_line do |line|
        line.chomp!
        break if !ignoring && line[0..DONE_AT.length-1] == DONE_AT
        if ignoring && line == IGNORE_BEFORE
          waiting = IGNORE_AFTER+1
        end
        if !ignoring
          parse_line(line)
        end
        if ignoring && waiting
          waiting -= 1
          if waiting <= 0
            ignoring = false
          end
        end
      end
      if @data_unwritten
        output_quote_data_line(@quote_data_output)
      end
      @quotes_output.close
      @quote_data_output.close
    end

    def parse_line(line)
      if line[/^# (.*)/]
        name = $1
        @quote_id = nil
        @movie_id = Movies.lookup_id(name)
        if !@movie_id
          @missed += 1
          return
        end
        @quote_sort = 0
        @data_sort = 0
        @data = []
        @data_unwritten = false
      elsif !@movie_id
        return
      elsif line[/^\s*$/]
        if @data_unwritten
          output_quote_data_line(@quote_data_output)
        end
        @data_unwritten = false
        @data_sort = 0
        @data = []
        @quote_id = nil
      elsif line[/^(\S.*)/]
        if !@quote_id
          @quote_id = get_id
          @quote_sort += 1
          @quote_sort_order = @quote_sort
          @data_sort = 0
          @data = []
          @data_unwritten = false
          output_quotes_line(@quotes_output)
        end
        if @data_unwritten
          output_quote_data_line(@quote_data_output)
        end
        @data << $1
        @data_unwritten = true
      elsif line[/^\s+(.*)/]
        @data << $1
        @data_unwritten = true
      end
    end

    def output_quotes_line(output_file)
      line = [@quote_id, @movie_id, @quote_sort_order].join("\t")
      output_file.puts(line)
    end

    def output_quote_data_line(output_file)
      @data_id = get_data_id
      @data_sort += 1
      @data_sort_order = @data_sort
      @data = @data.join(" ")
      line = [@data_id, @quote_id, @data, @data_sort_order, @data.norm].detab.join("\t")
      output_file.puts(line)
      @data = []
    end

    def get_id
      @max_id += 1
      return @max_id
    end

    def get_data_id
      @max_data_id += 1
      return @max_data_id
    end
  end
end
