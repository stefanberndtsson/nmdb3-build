require 'people'

module Nmdb
  class AkaNames
    attr_reader :missed

    IGNORE_BEFORE="AKA NAMES LIST"
    IGNORE_AFTER=4
    DONE_AT=""

    def initialize(input_file, aka_names_file)
      @aka_names_output = File.open(aka_names_file, "w")
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
      @aka_names_output.close
    end

    def parse_line(line)
      return if line[/^\s*$/]

      if line[/^(\S.*)/]
        @person_id = People.lookup_id($1)
        if !@person_id
          @missed += 1
          return
        end
        @aka_sort_order = 0
      elsif !@person_id
        return
      elsif line[/^   \(aka (.*)\)/]
        @aka_sort_order += 1
        @aka_sort = @aka_sort_order
        @aka_name = $1
        output_aka_names_line(@aka_names_output)
      end
    end

    def output_aka_names_line(output_file)
      @aka_id = get_id
      line = [@aka_id, @person_id, @aka_name, @aka_sort, @aka_name.norm].detab.join("\t")
      output_file.puts(line)
    end

    def get_id
      @max_id += 1
      return @max_id
    end
  end
end
