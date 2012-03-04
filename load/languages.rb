require 'movies'

module Nmdb
  class Languages
    attr_reader :missed

    IGNORE_BEFORE="LANGUAGE LIST"
    IGNORE_AFTER=1
    DONE_AT="-------------------------------------"

    def initialize(input_file, language_file, link_file)
      @language_output = File.open(language_file, "w")
      @link_output = File.open(link_file, "w")
      @missed = 0
      @max_language_id = 0
      @max_link_id = 0
      @language_ids = {}
      @languages_in_use = {}
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
      @language_output.close
      @link_output.close
    end

    def parse_line(line)
      clear_vars
      name,@language,@language_info = line.split(/\t+/)
      if !@language || @language.empty?
        @language = "Unknown"
      end

      @movie_id = Movies.lookup_id(name)
      if !@movie_id
        @missed += 1
        return
      end
      @languages_in_use[@movie_id] ||= []

      @language_id = @language_ids[@language]
      if !@language_id
        @language_id = get_language_id
        @language_ids[@language] = @language_id
        output_language_line(@language_output)
      end

      if @languages_in_use[@movie_id].include?(@language_id)
        return
      else
        @languages_in_use[@movie_id] << @language_id
      end
      output_link_line(@link_output)
    end

    def output_language_line(output_file)
      line = [@language_id, @language].detab.join("\t")
      output_file.puts(line)
    end

    def output_link_line(output_file)
      @id = get_link_id
      line = [@id, @movie_id, @language_id, @language_info].detab.join("\t")
      output_file.puts(line)
    end

    def clear_vars
      @id = nil
      @movie_id = nil
      @language_id = nil
      @language = nil
    end

    def get_language_id
      @max_language_id += 1
      return @max_language_id
    end

    def get_link_id
      @max_link_id += 1
      return @max_link_id
    end
  end
end
