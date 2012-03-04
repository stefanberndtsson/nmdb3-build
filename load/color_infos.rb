require 'movies'

module Nmdb
  class ColorInfos
    attr_reader :missed

    IGNORE_BEFORE="COLOR INFO LIST"
    IGNORE_AFTER=1
    DONE_AT="----------------------------"

    def initialize(input_file, color_infos_file)
      @color_infos_output = File.open(color_infos_file, "w")
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
      @color_infos_output.close
    end

    def parse_line(line)
      return if line[/^\s*$/]

      name,@color,@info = line.split(/\t+/)

      @movie_id = Movies.lookup_id(name)
      if !@movie_id
        @missed += 1
        return
      end

      return if !@color || @color.empty?

      output_color_infos_line(@color_infos_output)
    end

    def output_color_infos_line(output_file)
      @color_id = get_id
      line = [@color_id, @movie_id, @color, @info].detab.join("\t")
      output_file.puts(line)
    end

    def get_id
      @max_id += 1
      return @max_id
    end
  end
end
