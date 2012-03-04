require 'movies'
require 'people'

module Nmdb
  class Goofs
    attr_reader :missed

    IGNORE_BEFORE="GOOFS LIST"
    IGNORE_AFTER=2
    DONE_AT=""

    def initialize(input_file, goofs_file)
      @goofs_output = File.open(goofs_file, "w")
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
      @goofs_output.close
    end

    def parse_line(line)
      if line[/^\s*$/]
        if @empty_line
          @movie_id = nil
        else
          if @movie_id
            output_goofs_line(@goofs_output)
            @goofs = []
            @goof_type = nil
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
        @goofs = []
        @goof_type = nil
      elsif !@movie_id
        return
      elsif line[/^- (\S+): SPOILER: (.*)/]
        @goof_type = $1
        @spoiler = true
        @goofs << $2
      elsif line[/^- (\S+): (.*)/]
        @goof_type = $1
        @spoiler = false
        @goofs << $2
      elsif line[/^  (.*)/]
        @goofs << $1
      end
    end

    def output_goofs_line(output_file)
      @goofs_id = get_id
      goofs = @goofs.join(" ")
      goofs_parsed = parse_goofs(goofs)
      goofs_norm = parse_goofs(goofs, :norm).norm
      line = [@goofs_id, @movie_id, @goof_type, @spoiler, goofs_parsed, goofs_norm].detab.join("\t")
      output_file.puts(line)
      @goofs_id = nil
    end

    def parse_goofs(goofs, type = :main)
      goofs.gsub(/_(.*?)_ ?\(qv\)/) do |repl|
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
