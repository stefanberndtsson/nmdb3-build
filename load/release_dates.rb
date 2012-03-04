require 'movies'
require 'time'

module Nmdb
  class ReleaseDates
    attr_reader :missed

    IGNORE_BEFORE="RELEASE DATES LIST"
    IGNORE_AFTER=1
    DONE_AT="----------------------------"

    def initialize(input_file, release_dates_file)
      @release_dates_output = File.open(release_dates_file, "w")
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
      @release_dates_output.close
    end

    def parse_line(line)
      clear_vars
      return if line[/^\s*$/]

      name,release_date_data,@info = line.split(/\t+/)

      @movie_id = Movies.lookup_id(name)
      if !@movie_id || !release_date_data || release_date_data.empty?
        @missed += 1
        return
      end

      @country,stamp = release_date_data.split(":")
      @text_stamp = stamp
      if !stamp
        if @country[/\d/]
          stamp = @country
          @text_stamp = stamp
          @country = nil
        else
          stamp = nil
          @text_stamp = nil
        end
      end

      if stamp
        if stamp[/^\d\d\d\d$/]
          # Likely a year.
          @release_date_stamp = Time.parse("January #{stamp}")
        else
          begin
            @release_date_stamp = Time.parse(stamp)
          rescue ArgumentError
            @release_date_stamp = nil
          end
        end
      end

      output_release_dates_line(@release_dates_output)
    end

    def output_release_dates_line(output_file)
      @release_date_id = get_id
      line = [@release_date_id, @movie_id, @country, @text_stamp, @release_date_stamp, @info].detab.join("\t")
      output_file.puts(line)
    end

    def clear_vars
      @release_date_id = nil
      @movie_id = nil
      @country = nil
      @text_stamp = nil
      @release_date_stamp = nil
      @info = nil
    end

    def get_id
      @max_id += 1
      return @max_id
    end
  end
end
