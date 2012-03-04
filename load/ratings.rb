require 'movies'

module Nmdb
  class Ratings
    attr_reader :missed

    IGNORE_BEFORE="MOVIE RATINGS REPORT"
    IGNORE_AFTER=2
    DONE_AT="----------------------------"

    def initialize(input_file, ratings_file)
      @ratings_output = File.open(ratings_file, "w")
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
      @ratings_output.close
    end

    def parse_line(line)
      clear_vars
      return if line[/^\s*$/]

      @rating_map,votes,rating,name = line.scan(/^      ([0-9.\*]{10})  ([0-9 ]{6})  ([0-9 ]{2}\.\d)  (.*)$/).first

      @movie_id = Movies.lookup_id(name)
      if !@movie_id
        @missed += 1
        return
      end

      @rating_id = get_id
      @votes = votes.to_i
      @rating = rating.to_f

      output_rating_line(@ratings_output)
    end

    def output_rating_line(output_file)
      line = [@rating_id, @movie_id, @rating, @votes, @rating_map].join("\t")
      output_file.puts(line)
    end

    def clear_vars
      @rating_id = nil
      @movie_id = nil
      @votes = nil
      @rating = nil
      @rating_map = nil
    end

    def get_id
      @max_id += 1
      return @max_id
    end
  end
end
