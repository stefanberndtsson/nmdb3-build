require 'movies'
require 'iconv'

module Nmdb
  class MovieAkas
    attr_reader :missed

    IGNORE_BEFORE="AKA TITLES LIST"
    IGNORE_AFTER=4
    DONE_AT="-------------------------------"

    def initialize(input_files, output_file)
      @max_id = 0
      @missed = 0
      @output = File.open(output_file, "w")
      input_files.each do |input_file|
        ignoring = true
        waiting = nil
        next if !File.exist?(input_file)
        File.open(input_file).each_line do |line|
          line.chomp!
          break if !ignoring && line[0..DONE_AT.length-1] == DONE_AT
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
        if @movie_id && @has_aka
          output_line(@output)
        end
      end

      @output.close
    end

    def reencode_title(title, info)
      coding = nil
      if info && info.match(/(KOI8-R|ISO-8859-7|ISO-LATIN-2)/)
        coding = $1
        coding.gsub!(/ISO-LATIN-2/, "iso-8859-2")
      end
      return title if !coding
      latin1_title = Iconv.conv("iso-8859-1", "utf-8", title)
      Iconv.conv("utf-8", coding, latin1_title)
    end

    def parse_line(line)
      if line[/^\S.*$/]
        @movie_id = Movies.lookup_id(line)
        @has_aka = false
        if !@movie_id
          @missed += 1
          return
        end
      elsif line[/^   \(aka ([^\t]+)\)(|\t(.*))$/]
        return if !@movie_id
        if @has_aka
          output_line(@output)
        end
        @aka_title = $1
        @aka_info = $3
        @has_aka = true
      elsif line[/^$/]
        if @movie_id
          output_line(@output)
        end
        clear_vars
      end
    end

    def clear_vars
      @movie_id = nil
      @aka_title = nil
      @aka_info = nil
      @id = nil
      @has_aka = false
    end

    def output_line(output_file)
      @id = get_id
      aka_norm = nil
      @aka_title = reencode_title(@aka_title, @aka_info)
      if @aka_title.index("{")
        aka_norm = strip_episode_data(@aka_title).norm
      else
        aka_norm = strip_year(@aka_title).norm
      end

      if !aka_norm[/[0-9a-z]/]
        aka_norm = ""
      else
        aka_norm = aka_norm.hardtrim
      end

      line = [
        @id, @movie_id, @aka_title, @aka_info, aka_norm
      ].detab.join("\t")
      output_file.puts(line)
    end

    def get_id
      @max_id += 1
      return @max_id
    end

    def strip_year(title)
      m = Movies.new
      m.extract_title_year(title)
    end

    def strip_episode_data(title)
      m = Movies.new
      title = m.extract_episode(title)
      title = m.extract_title_year(title)
      "#{title} #{m.episode_name}"
    end
  end
end
