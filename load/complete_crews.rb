require 'movies'

module Nmdb
  class CompleteCrews
    attr_reader :missed

    IGNORE_BEFORE="CREW COVERAGE TRACKING LIST"
    IGNORE_AFTER=1
    DONE_AT="----------------------------"

    def initialize(input_file, complete_crew_file, complete_crew_status_file)
      @complete_crew_output = File.open(complete_crew_file, "w")
      @complete_crew_status_output = File.open(complete_crew_status_file, "w")
      output_statuses(@complete_crew_status_output)
      @complete_crew_status_output.close
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
      @complete_crew_output.close
    end

    def parse_line(line)
      clear_vars
      name,@complete_crew_status = line.split(/\t+/)
      if !@complete_crew_status || @complete_crew_status.empty? || !crew_status.keys.include?(@complete_crew_status)
        STDERR.puts("DEBUG: Missed! Complete crew empty or missing.") if $debug
        @missed += 1
        return
      end
      @movie_id = Movies.lookup_id(name)
      if !@movie_id
        @missed += 1
        return
      end

      @complete_crew_id = get_id
      @complete_crew_status_id = crew_status[@complete_crew_status]
      output_complete_crew_line(@complete_crew_output)
    end

    def output_complete_crew_line(output_file)
      line = [@complete_crew_id, @movie_id, @complete_crew_status_id].join("\t")
      output_file.puts(line)
    end

    def clear_vars
      @movie_id = nil
      @complete_crew_id = nil
      @complete_crew_status_id = nil
    end

    def get_id
      @max_id += 1
      return @max_id
    end

    def crew_status
      {
        "Complete" => 1,
        "Complete+Verified" => 2
      }
    end

    def output_statuses(output_file)
      crew_status.keys.each do |status|
        line = [crew_status[status], status].join("\t")
        output_file.puts(line)
      end
    end
  end
end
