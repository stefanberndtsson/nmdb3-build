require 'movies'

module Nmdb
  class People
    DONE_AT = "--------------------------"
    attr_accessor :full_name

    def initialize(input_dir, people_file, occupations_file, roles_file)
      @input_dir = input_dir
      @roles_output = File.open(roles_file, "w")
      @people_output = File.open(people_file, "w")
      @occupations_output = File.open(occupations_file, "w")
      @written_ids = {}

      roles = People.file_data.keys.sort_by {|x| People.file_data[x][:id]}
      roles.each do |role_name|
        @role_name = role_name
        next if !File.exist?(input_file(role_name))
        STDERR.puts("#{Time.now}: Opening #{input_file(role_name)}") if $debug
        output_role_line(@roles_output, role_name)

        ignoring = true
        waiting = nil
        File.open(input_file(role_name)).each_line do |line|
          line.chomp!
          break if !ignoring && line[0..DONE_AT.length-1] == DONE_AT && role_name != "biography"
          if ignoring && line == role_data(role_name)[:start]
            waiting = (role_data(role_name)[:skips] || 4)+1
          end
          if !ignoring
            parse_line(role_data(role_name), line)
          end
          if ignoring && waiting
            waiting -= 1
            if waiting <= 0
              ignoring = false
            end
          end
        end
      end

      @roles_output.close
      @people_output.close
      @occupations_output.close
    end

    def parse_line(role_info, line)
      if line[/^\s*$/]
        clear_vars
      end
      if (@role_name != "biography" && line[/^\S/])
        @full_name,movie_data = line.split(/\t+/)
        @full_name.gsub!(/,$/,"")
        @person_id = People.lookup_id(@full_name)
        if !@written_ids[@person_id]
          @person_id = People.get_id(self)
          parse_name(@full_name)
          output_people_line(@people_output)
        end
        return if !parse_movie_data(movie_data)
        output_occupations_line(@occupations_output, role_info)
      elsif (@role_name == "biography" && line[/^NM: (.*)/])
        @full_name = $1
        @full_name.gsub!(/,$/,"")
        @person_id = People.lookup_id(@full_name)
        if @written_ids[@person_id]
          @person_id = nil
          return
        end
        @person_id = People.get_id(self)
        parse_name(@full_name)
        output_people_line(@people_output)
      elsif line[/^\t+(.*)/]
        movie_data = $1
        return if !parse_movie_data(movie_data)
        output_occupations_line(@occupations_output, role_info)
      end
      clear_vars(false)
    end

    def parse_name(name)
      @first_name, @last_name, @people_count = People.reverse_name(name, true, true)
    end

    def parse_movie_data(movie_data)
      movie_name, *rest = movie_data.split(/  /,-1)
      @movie_id = Movies.lookup_id(movie_name)
      return false if !@movie_id
      rest.each do |part|
        if part[/^(\(.*\))$/]
          @extras = $1
        elsif part[/^\[(.*)\]$/]
          @character = $1
        elsif part[/^\<(.*)\>$/]
          @sort_value = $1
        end
      end

      @occupation_score = 0
      if role_group(@role_name) == 1   # Actor/Actress
        if !@character || @character[/^\s*$/]
          @occupation_score = 2
        else
          @occupation_score = 4
        end
      end

      if @character && @character[/(himself|herself|themselves|extra)/i]
        @occupation_score = 1
      end

      if @extras && @extras[/(archive footage|uncredited)/i]
        @occupation_score -= 2
      end

      @occupation_score = 0 if @occupation_score < 0
      return true
    end

    def clear_vars(all = true)
      @full_name = nil if all
      @person_id = nil if all
      @first_name = nil if all
      @last_name = nil if all
      @people_count = nil if all
      @movie_id = nil
      @extras = nil
      @character = nil
      @sort_value = nil
      @occupation_score = 0
    end

    def output_people_line(output_file)
      @written_ids[@person_id] = true
      name_norm = reverse_name(false).norm
      line = [@person_id, @full_name, @first_name, @last_name, @people_count, name_norm].detab.join("\t")
      output_file.puts(line)
    end

    def output_occupations_line(output_file, role_info)
      character_norm = (@character && !@character.empty?) ? @character.norm : ""
      line = [People.get_occupations_id, @person_id, @movie_id, role_info[:id],
        @character, @sort_value, @extras, @occupation_score, 1, false, character_norm].detab.join("\t")
      output_file.puts(line)
    end

    def output_role_line(output_file, role_name)
      line = [role_data(role_name)[:id], role_data(role_name)[:group], role_name].join("\t")
      output_file.puts(line)
    end

    def reverse_name(include_count = true, return_parts = false)
      People.reverse_name(@full_name, include_count, return_parts)
    end

    def self.reverse_name(name, include_count = true, return_parts = false)
      if name.scan(/^([^,]*), (.*?)(| \(([IVX]+)\))$/).first
        first_name = $2
        last_name = $1
        person_count = $4
        return [first_name, last_name, person_count] if return_parts
        person_count = nil if !include_count
        return ([first_name, last_name, person_count ? "(#{person_count})" : nil]-[nil]).join(" ")
      elsif name.scan(/^(.*?)(| \(([IVX]+)\))$/).first
        first_name = $1
        last_name = nil
        person_count = $3
        return [first_name, last_name, person_count] if return_parts
        person_count = nil if !include_count
        return ([first_name, last_name, person_count ? "(#{person_count})" : nil]-[nil]).join(" ")
      end
      raise WeirdNameError
    end

    def input_file(role_name)
      "#{@input_dir}/#{People.file_data[role_name][:file]}"
    end

    def role_data(role_name)
      People.file_data[role_name]
    end

    def role_group(role_name)
      People.file_data[role_name][:group]
    end

    def self.file_data
      @@file_data ||= {
        "actor" => {
          :file => "actors.list",
          :start => "THE ACTORS LIST",
          :id => 1,
          :group => 1
        },
        "actress" => {
          :file => "actresses.list",
          :start => "THE ACTRESSES LIST",
          :id => 2,
          :group => 1
        },
        "cinematographer" => {
          :file => "cinematographers.list",
          :start => "THE CINEMATOGRAPHERS LIST",
          :id => 3,
          :group => 2
        },
        "composer" => {
          :file => "composers.list",
          :start => "THE COMPOSERS LIST",
          :id => 4,
          :group => 2
        },
        "costume-designer" => {
          :file => "costume-designers.list",
          :start => "THE COSTUME DESIGNERS LIST",
          :id => 5,
          :group => 2
        },
        "director" => {
          :file => "directors.list",
          :start => "THE DIRECTORS LIST",
          :id => 6,
          :group => 3
        },
        "editor" => {
          :file => "editors.list",
          :start => "THE EDITORS LIST",
          :skips => 5,
          :id => 7,
          :group => 2
        },
        "miscellaneous" => {
          :file => "miscellaneous.list",
          :start => "THE MISCELLANEOUS FILMOGRAPHY LIST",
          :skips => 5,
          :id => 8,
          :group => 2
        },
        "producer" => {
          :file => "producers.list",
          :start => "THE PRODUCERS LIST",
          :id => 9,
          :group => 3
        },
        "production-designer" => {
          :file => "production-designers.list",
          :start => "THE PRODUCTION DESIGNERS LIST",
          :id => 10,
          :group => 2
        },
        "writer" => {
          :file => "writers.list",
          :start => "THE WRITERS LIST",
          :id => 11,
          :group => 3
        },
        "biography" => {
          :file => "biographies.list",
          :start => "BIOGRAPHY LIST",
          :skips => 1,
          :id => 12,
          :group => 4
        }
      }
    end

    def self.files_to_read
      file_data.keys.map do |role|
        file_data[role][:file]
      end
    end
  end
end

require 'load_people_ids'
