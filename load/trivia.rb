require 'movies'
require 'people'

module Nmdb
  class Trivia
    attr_reader :missed

    IGNORE_BEFORE="FILM TRIVIA"
    IGNORE_AFTER=2
    DONE_AT=""

    def initialize(input_file, trivia_file)
      @trivia_output = File.open(trivia_file, "w")
      @missed = 0
      @max_id = 0
      ignoring = true
      waiting = nil
      File.open(input_file).each_line do |line|
        line.chomp!
#        break if !ignoring && line[0..DONE_AT.length-1] == DONE_AT
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
      @trivia_output.close
    end

    def parse_line(line)
      if line[/^\s*$/]
        if @empty_line
          @movie_id = nil
        else
          if @movie_id
            output_trivia_line(@trivia_output)
            @trivia = []
            @spoiler = nil
          end
        end
        @empty_line = true
        return
      else
        @empty_line = false
      end

      if line[/^# (.*)/]
        name = $1
        @movie_id = Movies.lookup_id(name)
        if !@movie_id
          @missed += 1
          return
        end
        @trivia = []
      elsif !@movie_id
        return
      elsif line[/^- SPOILER: (.*)/]
        @spoiler = true
        @trivia << $1
      elsif line[/^- (.*)/]
        @spoiler = false
        @trivia << $1
      elsif line[/^  (.*)/]
        @trivia << $1
      end
    end

    def output_trivia_line(output_file)
      @trivia_id = get_id
      trivia = @trivia.join(" ")
      trivia_parsed = parse_trivia(trivia)
      trivia_norm = parse_trivia(trivia, :norm).norm
      line = [@trivia_id, @movie_id, @spoiler, trivia_parsed, trivia_norm].detab.join("\t")
      output_file.puts(line)
      @trivia_id = nil
    end

    def parse_trivia(trivia, type = :main)
      trivia.gsub(/_(.*?)_ ?\(qv\)/) do |repl|
        mlink_id = Movies.lookup_id($1)
        tmp = $1
        if mlink_id && type != :norm
          tmp = "@@MID@#{mlink_id}@@"
        end
        tmp
      end.gsub(/(^|[^a-zA-Z0-9])'(.*?)' ?\(qv\)/) do |repl|
        plink_id = People.lookup_id($2)
        tmp = "#{$1}#{$2}"
        if plink_id
          if type != :norm
            tmp = "#{$1}@@PID@#{plink_id}@@"
          end
        end
        tmp
      end
    end

    def get_id
      @max_id += 1
      return @max_id
    end
  end
end
