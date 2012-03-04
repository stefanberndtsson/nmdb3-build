require 'movies'

module Nmdb
  class RunningTimes
    attr_reader :missed

    IGNORE_BEFORE="RUNNING TIMES LIST"
    IGNORE_AFTER=1
    DONE_AT="----------------------------"

    def initialize(input_file, running_time_file)
      @running_time_output = File.open(running_time_file, "w")
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
      @running_time_output.close
    end

    def parse_line(line)
      clear_vars
      name,running_time,@running_time_info = line.split(/\t+/)
      if !running_time || running_time.empty?
        STDERR.puts("DEBUG: Missed! Running time empty or missing.") if $debug
        @missed += 1
        return
      end
      @movie_id = Movies.lookup_id(name)
      if !@movie_id
        @missed += 1
        return
      end

      @running_time_id = get_id
      parts = running_time.split(/:/)
      if parts.size > 1
        @running_time_value = parts[-1]
        @running_time_country = parts[0]
      else
        @running_time_country = nil
        @running_time_value = parts[0]
      end

      output_running_time_line(@running_time_output)
    end

    def output_running_time_line(output_file)
      line = [@running_time_id, @movie_id, @running_time_value, @running_time_country, @running_time_info].detab.join("\t")
      output_file.puts(line)
    end

    def clear_vars
      @id = nil
      @movie_id = nil
      @running_time_id = nil
      @running_time = nil
      @running_time_value = nil
      @running_time_country = nil
      @running_time_info = nil
    end

    def get_id
      @max_id += 1
      return @max_id
    end
  end
end
