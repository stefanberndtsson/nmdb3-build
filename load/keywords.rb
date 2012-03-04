require 'movies'

module Nmdb
  class Keywords
    attr_reader :missed

    IGNORE_BEFORE="8: THE KEYWORDS LIST"
    IGNORE_AFTER=2
    DONE_AT=""

    def initialize(input_file, keyword_file, link_file)
      @keyword_output = File.open(keyword_file, "w")
      @link_output = File.open(link_file, "w")
      @missed = 0
      @max_keyword_id = 0
      @max_link_id = 0
      @keyword_ids = {}
      @keywords_in_use = {}
      ignoring = true
      waiting = nil
      File.open(input_file).each_line do |line|
        line.chomp!
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
      @keyword_output.close
      @link_output.close
    end

    def parse_line(line)
      clear_vars
      name,@keyword = line.split(/\t+/)
      if !@keyword || @keyword.empty?
        STDERR.puts("DEBUG: Missed! Keyword empty or missing.") if $debug
        @missed += 1
        return
      end
      @movie_id = Movies.lookup_id(name)
      if !@movie_id
        @missed += 1
        return
      end
      @keywords_in_use[@movie_id] ||= []

      @keyword_id = @keyword_ids[@keyword]
      if !@keyword_id
        @keyword_id = get_keyword_id
        @keyword_ids[@keyword] = @keyword_id
        output_keyword_line(@keyword_output)
      end

      if @keywords_in_use[@movie_id].include?(@keyword_id)
        return
      else
        @keywords_in_use[@movie_id] << @keyword_id
      end
      output_link_line(@link_output)
    end

    def output_keyword_line(output_file)
      line = [@keyword_id, @keyword].detab.join("\t")
      output_file.puts(line)
    end

    def output_link_line(output_file)
      @id = get_link_id
      line = [@id, @movie_id, @keyword_id].join("\t")
      output_file.puts(line)
    end

    def clear_vars
      @id = nil
      @movie_id = nil
      @keyword_id = nil
      @keyword = nil
    end

    def get_keyword_id
      @max_keyword_id += 1
      return @max_keyword_id
    end

    def get_link_id
      @max_link_id += 1
      return @max_link_id
    end
  end
end
