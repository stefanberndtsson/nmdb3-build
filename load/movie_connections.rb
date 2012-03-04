require 'movies'

module Nmdb
  class MovieConnections
    attr_reader :missed

    IGNORE_BEFORE="MOVIE LINKS LIST"
    IGNORE_AFTER=2
    DONE_AT=""

    def initialize(input_file, output_file, connection_types_file)
      @max_id = 0
      @missed = 0
      @output = File.open(output_file, "w")
      @connection_types_output = File.open(connection_types_file, "w")
      output_connection_types(@connection_types_output)
      @connection_types_output.close
      ignoring = true
      waiting = nil
      File.open(input_file).each_line do |line|
        line.chomp!
        #          break if !ignoring && line[0..DONE_AT.length-1] == DONE_AT
        if ignoring && line[0..IGNORE_BEFORE.size-1] == IGNORE_BEFORE
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

      @output.close
    end

    def parse_line(line)
      if line[/^\s*$/]
        @movie_id = nil
        @linked_movie_id = nil
        return
      end
      if line[/^\S.*$/]
        @movie_id = Movies.lookup_id(line)
        if !@movie_id
          @missed += 1
          return
        end
      elsif !@movie_id
        return
      elsif line[/^  \(#{connection_types_match} (.*)\)$/]
        @connection_type_id = connection_type_id($1)
        return if !@connection_type_id
        link_name = $2
        @linked_movie_id = Movies.lookup_id(link_name)
        return if !@linked_movie_id
        output_line(@output)
      end
    end

    def output_line(output_file)
      @connection_id = get_id

      line = [
        @connection_id, @movie_id, @linked_movie_id, @connection_type_id
      ].join("\t")
      output_file.puts(line)
    end

    def get_id
      @max_id += 1
      return @max_id
    end

    def connection_types
      @@connection_types ||= [
        { :name => "alternate language version of", :sort => 3 },
        { :name => "edited from", :sort => 13 },
        { :name => "edited into", :sort => 14 },
        { :name => "featured in", :sort => 16 },
        { :name => "features", :sort => 15 },
        { :name => "followed by", :sort => 2 },
        { :name => "follows", :sort => 1 },
        { :name => "referenced in", :sort => 12 },
        { :name => "references", :sort => 11 },
        { :name => "remade as", :sort => 5 },
        { :name => "remake of", :sort => 6 },
        { :name => "spin off from", :sort => 8 },
        { :name => "spin off", :sort => 7 },
        { :name => "spoofed in", :sort => 10 },
        { :name => "spoofs", :sort => 9 },
        { :name => "version of", :sort => 4 }
      ]
    end

    def connection_types_match
      "("+connection_types.map {|x| x[:name]}.join("|")+")"
    end

    def connection_type_id(type)
      connection_types.each_with_index do |conn_type,i|
        if conn_type[:name] == type
          return i+1
        end
      end
      return nil
    end

    def output_connection_types(output_file)
      connection_types.each_with_index do |conn_type,i|
        line = [i+1, conn_type[:name], conn_type[:sort]].join("\t")
        output_file.puts(line)
      end
    end
  end
end
