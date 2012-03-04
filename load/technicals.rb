require 'movies'

module Nmdb
  class Technicals
    attr_reader :missed

    IGNORE_BEFORE="TECHNICAL LIST"
    IGNORE_AFTER=3
#    DONE_AT=""

    def initialize(input_file, technical_file)
      @technical_output = File.open(technical_file, "w")
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
      @technical_output.close
    end

    def parse_line(line)
      return if line[/^\s*$/]

      name,data,@info = line.split(/\t+/)
      return if !data || !data.index(":")

      @movie_id = Movies.lookup_id(name)
      if !@movie_id
        @missed += 1
        return
      end

      @data_key,*values = data.split(":")
      return if !@data_key || @data_key.empty? || values.empty?
      @data_value = values.join(":")

      output_technical_line(@technical_output)
    end

    def output_technical_line(output_file)
      @technical_id = get_id
      line = [@technical_id, @movie_id, @data_key, @data_value, @info].join("\t")
      output_file.puts(line)
    end

    def get_id
      @max_id += 1
      return @max_id
    end
  end
end
