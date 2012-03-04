require 'movies'
require 'people'

module Nmdb
  class AlternateVersions
    attr_reader :missed

    IGNORE_BEFORE="ALTERNATE VERSIONS LIST"
    IGNORE_AFTER=3
    DONE_AT="---------------------------------------"

    def initialize(input_file, alternate_versions_file)
      @alternate_versions_output = File.open(alternate_versions_file, "w")
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
      @alternate_versions_output.close
    end

    def parse_line(line)
      if line[/^\s*$/]
        if @version_unwritten
          output_alternate_versions_line(@alternate_versions_output)
          @version = []
          @version_id = nil
          @last_version_id = nil
          @spoiler = nil
        end
        @version_unwritten = false
      end

      if line[/^# (.*)/]
        name = $1
        @movie_id = Movies.lookup_id(name)
        if !@movie_id
          @missed += 1
          return
        end
        @version_id = nil
        @last_version_id = nil
        @last_is_sub = false
        @version = []
        @version_unwritten = false
      elsif !@movie_id
        return
      elsif line[/^- SPOILER. (.*)/]
        if @version_unwritten
          output_alternate_versions_line(@alternate_versions_output)
        end
        @last_version_id = nil
        @last_is_sub = false
        @spoiler = true
        @version = [$1]
        @version_unwritten = true
      elsif line[/^- (.*)/]
        if @version_unwritten
          output_alternate_versions_line(@alternate_versions_output)
        end
        @last_version_id = nil
        @last_is_sub = false
        @spoiler = false
        @version = [$1]
        @version_unwritten = true
      elsif line[/^\s+- (.*)/]
        return if !@version_unwritten
        output_alternate_versions_line(@alternate_versions_output)
        @last_version_id = @version_id if !@last_is_sub
        @last_is_sub = true
        @version = [$1]
        @version_unwritten = true
      elsif line[/^ \s+(.*)/]
        @version << $1
        @version_unwritten = true
      end
    end

    def output_alternate_versions_line(output_file)
      @version_id = get_id
      version = @version.join(" ")
      version_parsed = parse_version(version)
#      version_norm = parse_version(version, :norm).norm
      line = [@version_id, @movie_id, @last_version_id, @spoiler, version_parsed].detab.join("\t")
      output_file.puts(line)
#      @version_id = nil
    end

    def parse_version(version, type = :main)
      version.gsub(/_(.*?)_ ?\(qv\)/) do |repl|
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
