require 'movies'
require 'people'

module Nmdb
  class Plot
    attr_reader :missed

    IGNORE_BEFORE="PLOT SUMMARIES LIST"
    IGNORE_AFTER=2
    DONE_AT=""

    def initialize(input_file, plot_file)
      @plot_output = File.open(plot_file, "w")
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
      @plot_output.close
#      puts "Missed: #{@missed}"
    end

    def parse_line(line)
      if line[/^\s*$/]
        @passed_empty = true if !@plot.empty?
        return
      end

      if line[/^MV: (.*)/]
        name = $1
        @movie_id = Movies.lookup_id(name)
        if !@movie_id
          @missed += 1
          return
        end
        @plot = []
        @author = nil
        @passed_empty = false
      elsif !@movie_id
        return
      elsif line[/^PL: (.*)/]
        if @passed_empty && !@author && !@plot.empty?
          output_plot_line(@plot_output)
          @plot = []
        end
        @plot << $1
        @passed_empty = false
      elsif line[/^BY: (.*)/]
        @author = $1
        output_plot_line(@plot_output)
        @plot = []
        @author = nil
        @passed_empty = false
      elsif line[/^-{30,9999}$/]
        @movie_id = nil
      end
    end

    def output_plot_line(output_file)
      @plot_id = get_id
      plot = @plot.join(" ")
      plot_parsed = parse_plot(plot)
      plot_norm = parse_plot(plot, :norm).norm
      line = [@plot_id, @movie_id, plot_parsed, @author, plot_norm].detab.join("\t")
      output_file.puts(line)
      @plot_id = nil
    end

    def parse_plot(plot, type = :main)
      plot.gsub(/_(.*?)_ ?\(qv\)/) do |repl|
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
