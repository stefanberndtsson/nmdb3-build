#!/usr/bin/env ruby

require 'tools'

module Nmdb
  # Ignore everything above "MOVIES LIST"
  # Ignore 2 lines below "MOVIES LIST"
  # Done with at line with no TAB and at least 40 "-"
  # One line per relevant entry
  # TAB separation between full_name and year
  # Episodes in {}
  # Year in ()
  # Episode data in () within {}
  class Movies
    attr_reader :full_title
    attr_reader :title, :episode_name

    IGNORE_BEFORE="MOVIES LIST"
    IGNORE_AFTER=2
    DONE_AT="-----------------------------------"

    def initialize(input_file = nil, output_file = nil, dedup_file = nil, years_file = nil)
      return if !input_file
      @output = File.open(output_file, "w")
      @output_years = File.open(years_file, "w")
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
      @output.close
      @output_years.close
      STDERR.puts("#{Time.now}: Sorting and deduplicating data") if $debug
      sort_and_dedup_data(output_file, dedup_file)
    end

    def clear_vars
      @full_title = nil
      @id = nil
      @full_year = nil
      @is_episode = false
      @episode_parent_title = nil
      @title = nil
      @year = nil
      @year_open_end = false
      @episode_name = nil
      @episode_season = nil
      @episode_episode = nil
      @title_category = nil
      @title_year = nil
    end

    def parse_line(line)
      clear_vars
      name,year = line.split(/\t+/)
      if name.match(/ (\{\{SUSP(EN|NE)D(ED|)\}\})$/)
        return false
      end
      @full_title = name
      parse_name(name)
      @full_year = year
      parse_year(year)
      @id = Movies.get_id(self)

      output_line(@output)
      output_years(@output_years)
    end

    def parse_name(name)
      name = extract_episode(name)
      if @is_episode
        @episode_parent_title = name
      end
      name = extract_type(name)
      name = extract_title_year(name)
      @title = name
    end

    def parse_year(year)
      if !year || year.empty?
        @year = ["Unknown"]
      elsif year.to_i.to_s == year
        @year = [year.to_i]
      elsif year[/^(\d\d\d\d)-(\d\d\d\d)$/]
        @year = Range.new($1.to_i, $2.to_i).to_a
      elsif year[/^(\d\d\d\d)-\?\?\?\?$/]
        @year = Range.new($1.to_i, Time.now.year).to_a
        @year_open_end = true
      else
        @year = ["Unknown"]
      end
    end

    def extract_episode(name)
      position = name.rindex(") {")
      return name if position.nil?
      episode_data = name[position+3..-2]
      ev_position = episode_data.rindex(" (#")
      if !ev_position && episode_data[0..1] == "(#"
        ev_position = 0
      elsif ev_position
        ev_position += 1
      end
      ev_data = nil
      ep_name = ""
      if ev_position
        ev_data = episode_data[ev_position+2..-2].split(".")
        if ev_data.size != 2
          ev_data = nil
          ev_position = 0
          ep_name = episode_data
        end
        if ev_position > 1
          ep_name = episode_data[0..ev_position-2]
        end
      else
        ep_name = episode_data
      end
      if ep_name && !ep_name.empty?
        @episode_name = ep_name
      end
      if ev_data && !ev_data.empty?
        @episode_season = ev_data[0]
        @episode_episode = ev_data[1]
      end
      @is_episode = true
      if position
        return name[0..position]
      end
    end

    def extract_type(name)
      if name[0] == "\""
        @title_category = "TVS"
        return name
      end

      if name[/\((TV|V|VG)\)$/]
        @title_category = $1
        return name[0..-(@title_category.length+4)]
      end

      @title_category = ""
      return name
    end

    def extract_title_year(name)
      if name[/\((....(|\/[IVX]+))?\)$/]
        @title_year = $1
        return name[0..-(@title_year.length+4)]
      end
      return name
    end

    def self.split_title(title, nil_if_episode_named = false)
      m = Movies.new
      m.clear_vars
      m.parse_name(title)
      tmp = m.split_title_data(nil_if_episode_named ? false : true)
      tmp
    end

    def split_title_data(may_clear_ep_name = false)
      if may_clear_ep_name && (@episode_season && @episode_episode && !@episode_season.empty? && !@episode_episode.empty?)
        return [@title, @title_year, @title_category, "",
        @episode_season ? @episode_season.to_i : nil,
        @episode_episode ? @episode_episode.to_i : nil]
      else
        return [@title, @title_year, @title_category, @episode_name.to_s,
        @episode_season ? @episode_season.to_i : nil,
        @episode_episode ? @episode_episode.to_i : nil]
      end
    end

    def output_line(output_file)
      line = [
        @id, @full_title, @episode_parent_title, @title, @full_year,
        @year_open_end.inspect, @title_year, @title_category, @is_episode.inspect,
        @episode_name,
        @episode_season ? @episode_season.to_i : nil,
        @episode_episode ? @episode_episode.to_i : nil,
        "", @title.norm, @episode_name.norm
      ].detab.join("\t")
      output_file.puts(line)
    end

    def output_years(output_years_file)
      @year.each do |year|
        line = [
          Movies.get_years_id,
          @id,
          year
        ].join("\t")
        output_years_file.puts(line)
      end
    end

    def sort_and_dedup_data(input_file, output_file)
      STDERR.puts("#{Time.now}:  - loading and extracting") if $debug
      items = File.read(input_file).scan(/^(\d+)\t(.*)$/).map { |x| [x[0].to_i, x[1]] }
      STDERR.puts("#{Time.now}:  - sorting and grouping") if $debug
      item_groups = items.sort_by { |x| [x[0], -x[1].length] }.group_by { |x| x[0] }
      STDERR.puts("#{Time.now}:  - writing unique") if $debug
      File.open(output_file, "w") do |file|
        item_groups.keys.sort.each do |item|
          file.puts(item_groups[item].first.join("\t"))
        end
      end
      STDERR.puts("#{Time.now}:  - done") if $debug
    end
  end
end

require 'load_movies_ids'
