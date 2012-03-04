require 'movies'
require 'people'

module Nmdb
  class Soundtracks
    attr_reader :missed

    IGNORE_BEFORE="SOUNDTRACKS"
    IGNORE_AFTER=1
    DONE_AT=""

    def initialize(input_file, soundtrack_titles_file, soundtrack_title_data_file)
      @soundtrack_titles_output = File.open(soundtrack_titles_file, "w")
      @soundtrack_title_data_output = File.open(soundtrack_title_data_file, "w")
      @missed = 0
      @max_id = 0
      @max_data_id = 0
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
      if @data_unwritten
        output_soundtrack_title_data_line(@soundtrack_title_data_output)
      end
      @soundtrack_titles_output.close
      @soundtrack_title_data_output.close
    end

    def parse_line(line)
      if line[/^\s*$/]
        if @data_unwritten
          output_soundtrack_title_data_line(@soundtrack_title_data_output)
        end
        @movie_id = nil
        @title_id = nil
        @title_sort = 0
        @data_sort = 0
        @data_unwritten = false
        return
      end
      if line[/^# (.*)/]
        name = $1
        @title_id = nil
        @movie_id = Movies.lookup_id(name)
        if !@movie_id
          @missed += 1
          return
        end
        @title_sort = 0
        @data_sort = 0
        @data_unwritten = false
      elsif !@movie_id
        return
      elsif line[/^- (.*)/]
        if @data_unwritten
          output_soundtrack_title_data_line(@soundtrack_title_data_output)
        end
        @data_unwritten = false
        @title_id = get_id
        @title_sort += 1
        @title_sort_order = @title_sort
        @data_sort = 0
        @data = []
        @title = $1
        output_soundtrack_titles_line(@soundtrack_titles_output)
      elsif !@title_id
        return
      elsif line[/^   (.*)/]
        @data << $1
        @data_unwritten = true
      elsif line[/^  (.*)/]
        if @data_unwritten
          output_soundtrack_title_data_line(@soundtrack_title_data_output)
        end
        @data_sort += 1
        @data_sort_order = @data_sort
        @data = [$1]
        @data_unwritten = true
      end
    end

    def output_soundtrack_titles_line(output_file)
      @title = parse_links(@title)
      line = [@title_id, @movie_id, @title, @title_sort_order].detab.join("\t")
      output_file.puts(line)
    end

    def output_soundtrack_title_data_line(output_file)
      @data_id = get_data_id
      @data = @data.join(" ")
      @data = parse_links(@data)
      line = [@data_id, @title_id, @data, @data_sort_order].detab.join("\t")
      output_file.puts(line)
      @data = []
    end

    def parse_links(data, type = :main)
      data.gsub(/_(.*?)_ ?\(qv\)/) do |repl|
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

    def get_data_id
      @max_data_id += 1
      return @max_data_id
    end
  end
end
