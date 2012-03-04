require 'movies'

module Nmdb
  class Taglines
    attr_reader :missed

    IGNORE_BEFORE="TAG LINES LIST"
    IGNORE_AFTER=3
    DONE_AT="----------------------------"

    def initialize(input_file, taglines_file)
      @taglines_output = File.open(taglines_file, "w")
      @missed = 0
      @max_id = 0
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
      @taglines_output.close
    end

    def parse_line(line)
      if line[/^\s*$/]
        @movie_id = nil
        @tagline_sort = 0
        return
      end

      if line[/^# (.*)/]
        name = $1
        @movie_id = Movies.lookup_id(name)
        if !@movie_id
          @missed += 1
          return
        end
        @tagline_sort = 0
      elsif !@movie_id
        return
      elsif line[/^\t\s*(.*)/]
        @tagline_sort += 1
        @tagline_sort_order = @tagline_sort
        @tagline = $1
        output_taglines_line(@taglines_output)
      end
    end

    def output_taglines_line(output_file)
      @tagline_id = get_id
      line = [@tagline_id, @movie_id, @tagline, @tagline_sort_order].detab.join("\t")
      output_file.puts(line)
    end

    def get_id
      @max_id += 1
      return @max_id
    end
  end
end
