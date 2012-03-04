require 'movies'
require 'people'

module Nmdb
  class PersonMetadata
    attr_reader :missed

    IGNORE_BEFORE="BIOGRAPHY LIST"
    IGNORE_AFTER=2
    DONE_AT=""

    def initialize(input_file, person_metadata_file)
      @person_metadata_output = File.open(person_metadata_file, "w")
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
      @person_metadata_output.close
    end

    def parse_line(line)
      if line[/^\s*$/]
        if @last_type != "BG"
          if @unwritten_data
            @metadata_value = @metadata.join(" ")
            @metadata_count += 1
            @metadata_sort_order = @metadata_count
            @parse_links = true
            output_person_metadata_line(@person_metadata_output)
            @unwritten_data = false
          end
          @metadata_count = 0
        end
        return
      end

      if line[/^NM: (.*)/]
        if @unwritten_data && @last_type == "BG"
          @metadata_key = "BG"
          @metadata_value = @metadata.join(" ")
          @parse_links = true
          output_person_metadata_line(@person_metadata_output)
          @metadata = []
          @metadata_value = nil
          @unwritten_data = false
        end
        name = $1.gsub(/,$/,"")
        @person_id = People.lookup_id(name)
        if !@person_id
          @missed += 1
          return
        end
        @metadata_count = 0
        @author = nil
        @metadata = []
      elsif !@person_id
        return
      elsif line[/^(RN|NK|DB|DD|HT): (.*)/]
        @last_type = $1
        @metadata_key = $1
        @metadata_value = $2
        @metadata_count += 1
        @metadata_sort_order = @metadata_count
        @parse_links = false
        output_person_metadata_line(@person_metadata_output)
        @unwritten_data = false
        @author = nil
        @metadata = []
      elsif line[/^([A-Z][A-Z]): \* (.*)/]
        if @last_type == $1
          # Write out last pass...
          @metadata_value = @metadata.join(" ")
          @metadata_count += 1
          @metadata_sort_order = @metadata_count
          @parse_links = true
          output_person_metadata_line(@person_metadata_output)
          @unwritten_data = false
          @metadata_value = nil
          @author = nil
        end
        @last_type = $1
        @metadata_key = $1
        @metadata = [$2]
        @unwritten_data = true
      elsif line[/^BY: (.*)/]
        if @last_type == "BG"
          @metadata_key = "BG"
          @metadata_value = @metadata.join(" ")
          @author = $1
          @parse_links = true
          output_person_metadata_line(@person_metadata_output)
          @metadata = []
          @metadata_value = nil
          @unwritten_data = false
        end
        @last_type = "BG"
        @author = nil
      elsif line[/^([A-Z][A-Z]): \s*(.*)/]
        @last_type = $1
        @metadata_key = $1
        @metadata << $2
        @unwritten_data = true
      elsif line[/^-{30,9999}$/]
        @person_id = nil
      end
    end

    def output_person_metadata_line(output_file)
      @metadata_id = get_id
      if @parse_links
        metadata_norm = parse_metadata(@metadata_value, :norm).norm
        @metadata_value = parse_metadata(@metadata_value)
      else
        metadata_norm = @metadata_value.norm
      end
      line = [@metadata_id, @person_id, @metadata_key, @metadata_value, @metadata_sort_order, @author, metadata_norm].detab.join("\t")
      output_file.puts(line)
      @metadata_id = nil
    end

    def parse_metadata(metadata, type = :main)
      metadata.gsub(/_(.*?)_ ?\(qv\)/) do |repl|
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
