require 'movies'

module Nmdb
  class Genres
    attr_reader :missed

    IGNORE_BEFORE="8: THE GENRES LIST"
    IGNORE_AFTER=2
    DONE_AT=""

    def initialize(input_file, genre_file, link_file)
      @genre_output = File.open(genre_file, "w")
      @link_output = File.open(link_file, "w")
      @missed = 0
      @max_genre_id = 0
      @max_link_id = 0
      @genre_ids = {}
      @genres_in_use = {}
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
      @genre_output.close
      @link_output.close
    end

    def parse_line(line)
      clear_vars
      name,@genre = line.split(/\t+/)
      if !@genre || @genre.empty?
        STDERR.puts("DEBUG: Missed! Genre empty or missing.") if $debug
        @missed += 1
        return
      end
      @movie_id = Movies.lookup_id(name)
      if !@movie_id
        @missed += 1
        return
      end
      @genres_in_use[@movie_id] ||= []

      @genre_id = @genre_ids[@genre]
      if !@genre_id
        @genre_id = get_genre_id
        @genre_ids[@genre] = @genre_id
        output_genre_line(@genre_output)
      end

      if @genres_in_use[@movie_id].include?(@genre_id)
        return
      else
        @genres_in_use[@movie_id] << @genre_id
      end
      output_link_line(@link_output)
    end

    def output_genre_line(output_file)
      line = [@genre_id, @genre].detab.join("\t")
      output_file.puts(line)
    end

    def output_link_line(output_file)
      @id = get_link_id
      line = [@id, @movie_id, @genre_id].join("\t")
      output_file.puts(line)
    end

    def clear_vars
      @id = nil
      @movie_id = nil
      @genre_id = nil
      @genre = nil
    end

    def get_genre_id
      @max_genre_id += 1
      return @max_genre_id
    end

    def get_link_id
      @max_link_id += 1
      return @max_link_id
    end
  end
end
