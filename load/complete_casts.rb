require 'movies'

module Nmdb
  class CompleteCasts
    attr_reader :missed

    IGNORE_BEFORE="CAST COVERAGE TRACKING LIST"
    IGNORE_AFTER=1
    DONE_AT="----------------------------"

    def initialize(input_file, complete_cast_file, complete_cast_status_file)
      @complete_cast_output = File.open(complete_cast_file, "w")
      @complete_cast_status_output = File.open(complete_cast_status_file, "w")
      output_statuses(@complete_cast_status_output)
      @complete_cast_status_output.close
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
      @complete_cast_output.close
    end

    def parse_line(line)
      clear_vars
      name,@complete_cast_status = line.split(/\t+/)
      if !@complete_cast_status || @complete_cast_status.empty? || !cast_status.keys.include?(@complete_cast_status)
        STDERR.puts("DEBUG: Missed! Complete cast empty or missing.") if $debug
        @missed += 1
        return
      end
      @movie_id = Movies.lookup_id(name)
      if !@movie_id
        @missed += 1
        return
      end

      @complete_cast_id = get_id
      @complete_cast_status_id = cast_status[@complete_cast_status]
      output_complete_cast_line(@complete_cast_output)
    end

    def output_complete_cast_line(output_file)
      line = [@complete_cast_id, @movie_id, @complete_cast_status_id].join("\t")
      output_file.puts(line)
    end

    def clear_vars
      @movie_id = nil
      @complete_cast_id = nil
      @complete_cast_status_id = nil
    end

    def get_id
      @max_id += 1
      return @max_id
    end

    def cast_status
      {
        "Complete" => 1,
        "Complete+Verified" => 2
      }
    end

    def output_statuses(output_file)
      cast_status.keys.each do |status|
        line = [cast_status[status], status].join("\t")
        output_file.puts(line)
      end
    end
  end
end
