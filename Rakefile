# encoding: utf-8
require 'rake/clean'
Encoding.default_internal = Encoding.default_external = "UTF-8"
require 'pp'
require 'open-uri'
require 'iconv'
require 'zlib'
require 'yaml'
$: << "."
$: << "load"

verbose false

class DiffError < Exception
end

class MissedError < Exception
end

class SQLError < Exception
end

class ForkResultError < Exception
end

@data = YAML.load(File.read("build.conf"))
@pg_config = YAML.load(File.read("db.conf"))
@sphinx_config = YAML.load(File.read("sphinxsearch.conf"))
$debug = @data[:debug]

CLEAN.include('data/tmp/*')
CLEAN.include('test/tmp/*')
CLEAN.include('test/output/*')
CLEAN.include('overlap/data/*')
CLOBBER.include('data/download/*')
CLOBBER.include('data/output/*')

def input(filename = nil)
  ([@data[:base], @data[:input], filename]-[nil]).join("/")
end

def output(filename = nil)
  ([@data[:base], @data[:output], filename]-[nil]).join("/")
end

def tmp(filename = nil)
  ([@data[:base], @data[:tmp], filename]-[nil]).join("/")
end

def previous(filename = nil)
  ([@data[:base], @data[:previous], filename]-[nil]).join("/")
end

def expected(filename = nil)
  ([@data[:base], @data[:expected], filename]-[nil]).join("/")
end

def sqlscript(filename = nil)
  ([@data[:base], @data[:sqlscript], filename]-[nil]).join("/")
end

def overlap(filename = nil)
  ([@data[:base], @data[:overlap], filename]-[nil]).join("/")
end

def overlapdata(filename = nil)
  ([@data[:base], @data[:overlap], "data", filename]-[nil]).join("/")
end

def files_uptodate?(task_obj, compared_to, files, check_direct_files = false, namespace = "build:")
#  sleep 1
  compare_files = compared_to.map {|x| input(x) }
  tmp = nil
  if !check_direct_files
    taskname = task_obj.name
    tmp = files[taskname].map {|x| uptodate?(output(x), compare_files) }
    task_obj.prerequisites.each do |prereq|
      compare_files = files["#{namespace}#{prereq}"].map {|x| output(x) }
      tmp += files[taskname].map {|x| uptodate?(output(x), compare_files) }
    end
  else
    tmp = files.map {|x| uptodate?(output(x), compare_files) }
  end
  (tmp-[true]).empty?
end

def test?
  @data[:type] == :test
end

def upgrading?
  @data[:action] == :upgrade
end

def compare(file1, file2)
  cmd = "diff -u \"#{file1}\" \"#{file2}\""
  if !system(cmd)
    raise DiffError
  end
end

def load_movies_ids(skip_if_loaded = true, filename = nil)
  filename = filename || output("movies.dat")
  require 'movies'
  Nmdb::Movies.load_ids(filename, skip_if_loaded)
end

def load_people_ids(skip_if_loaded = true, filename = nil)
  filename = filename || output("people.dat")
  require 'people'
  Nmdb::People.load_ids(filename, skip_if_loaded)
end

def cleanup_ids
  require 'movies'
  require 'people'
  Nmdb::Movies.setup_ids
  Nmdb::People.setup_ids
  GC.start
end

desc "Run all tests."
task :test do
  $debug = true
  $test = true
  puts "Setting test mode" if $debug
  @data[:type] = :test
  @data[:base] = "test"
  @data[:expected] = "expected_output"
  Rake::Task[:default].invoke
end

task :profile do
  $debug = true
  $test = true
  puts "Starting profiler..." if $debug
  require 'ruby-prof'
  RubyProf.start
  Rake::Task[:default].invoke
  result = RubyProf.stop
  flat = RubyProf::FlatPrinter.new(result)
  flat.print(File.open("/tmp/flat.txt", "w"))
  graph = RubyProf::GraphPrinter.new(result)
  graph.print(File.open("/tmp/graph.txt", "w"))
  html = RubyProf::GraphHtmlPrinter.new(result)
  html.print(File.open("/tmp/graph.html", "w"))
end

desc "Build everything (same as upgrade)"
task :default do
  puts "default (#{@data[:type]})" if $debug
  Rake::Task["db:dump_ids"].invoke
  if !test?
    download_process = fork { Rake::Task[:download].invoke }
    Process.waitpid(download_process)
    raise ForkResultError if !$?.success?
  end
  build_process = fork { Rake::Task[:build].invoke }
  Process.waitpid(build_process)
  raise ForkResultError if !$?.success?
  Rake::Task[:db].invoke
  if !test?
    Rake::Task[:reindex_sphinx].invoke
    Rake::Task[:restart_apache].invoke
  end
end

task :build => "build:all" do
  puts "Running build (#{@data[:type]})" if $debug
end

task :db => "db:all" do
  puts "Running db (#{@data[:type]})" if $debug
end

desc "Fresh install, without reusing id's from previous run"
task :install do
  @data[:action] = :install
  # Create empty files for previous ids
  File.open(previous("movies_ids.dat"), "w") {|file| file.write("") }
  File.open(previous("people_ids.dat"), "w") {|file| file.write("") }
  $debug = false
  $test = false
  Rake::Task[:default].invoke
end

desc "Upgrade a previous build, keeping id's for movies and people"
task :upgrade do
  @data[:action] = :upgrade
  $debug = false
  $test = false
  Rake::Task[:default].invoke
end

task :download do
  @input_files = [
    "actors", "actresses", "aka-names", "aka-titles", "alternate-versions", "biographies",
    "business", "certificates", "cinematographers", "color-info", "complete-cast", "complete-crew",
    "composers", "costume-designers", "countries", "crazy-credits", "directors", "distributors",
    "editors", "genres", "german-aka-titles", "goofs", "iso-aka-titles", "italian-aka-titles",
    "keywords", "language", "laserdisc", "literature", "locations", "miscellaneous-companies",
    "miscellaneous", "movie-links", "movies", "mpaa-ratings-reasons", "plot", "producers",
    "production-companies", "production-designers", "quotes", "ratings", "release-dates",
    "running-times", "sound-mix", "soundtracks", "special-effects-companies", "taglines",
    "technical", "trivia", "writers"
  ]

  @input_files.each do |input_file|
    File.open(input("#{input_file}.list"), "w") do |local_file|
      open("#{@data[:input_source]}/#{input_file}.list.gz") do |remote_file|
        data = Zlib::GzipReader.new(remote_file).read
        STDERR.puts("DEBUG: #{Time.now}: Saving #{input_file}") if $debug
        local_file.write(Iconv.conv("utf-8", "iso-8859-1", data))
      end
    end
  end
end

task :reindex_sphinx do
  IO.popen(@sphinx_config[:sphinx_stop]) {|x| x.read }
  sleep 2
  IO.popen(@sphinx_config[:sphinx_index]) {|x| x.read }
  IO.popen(@sphinx_config[:sphinx_start]) {|x| x.read }
end

task :restart_apache do
  IO.popen(@data[:apache_restart]) {|x| x.read }
end

namespace "build" do |ns|
  @files = {
    "build:movies" => ["movies.dat", "movie_years.dat"],
    "build:people" => ["people.dat", "occupations.dat", "roles.dat"],
    "build:plot" => ["plots.dat"],
    "build:movie_akas" => ["movie_akas.dat"],
    "build:genres" => ["genres.dat", "movie_genres.dat"],
    "build:keywords" => ["keywords.dat", "movie_keywords.dat"],
    "build:languages" => ["languages.dat", "movie_languages.dat"],
    "build:running_times" => ["running_times.dat"],
    "build:complete_casts" => ["complete_casts.dat", "complete_cast_statuses.dat"],
    "build:complete_crews" => ["complete_crews.dat", "complete_crew_statuses.dat"],
    "build:ratings" => ["ratings.dat"],
    "build:trivia" => ["trivia.dat"],
    "build:goofs" => ["goofs.dat"],
    "build:person_metadata" => ["person_metadata.dat"],
    "build:movie_connections" => ["movie_connections.dat", "movie_connection_types.dat"],
    "build:release_dates" => ["release_dates.dat"],
    "build:soundtracks" => ["soundtrack_titles.dat", "soundtrack_title_data.dat"],
    "build:taglines" => ["taglines.dat"],
    "build:technicals" => ["technicals.dat"],
    "build:alternate_versions" => ["alternate_versions.dat"],
    "build:aka_names" => ["aka_names.dat"],
    "build:certificates" => ["certificates.dat"],
    "build:color_infos" => ["color_infos.dat"],
    "build:quotes" => ["quotes.dat", "quote_data.dat"]
  }
  task :all => :setup do
    puts "Done setup" if $debug
  end

  task :setup do
    if test?
      rm_f Dir.glob("#{output}/*")
      rm_f Dir.glob("#{tmp}/*")
    end
    mkdir_p input
    mkdir_p output
    mkdir_p previous
    mkdir_p tmp
  end

  task :movies do |t|
    next if files_uptodate?(t, ["movies.list"], @files)
    puts "Doing movies" if $debug
    require 'movies'
    load_movies_ids(false, previous("movies_ids.dat"))
    Nmdb::Movies.new(input("movies.list"), tmp("movies.tmp"), tmp("movies.build"), tmp("movie_years.build"))
    mv tmp("movies.build"), output("movies.dat")
    mv tmp("movie_years.build"), output("movie_years.dat")
    rm_f tmp("movies.tmp")
    if test?
      compare(output("movies.dat"), expected("movies.dat"))
      compare(output("movie_years.dat"), expected("movie_years.dat"))
    end
    load_movies_ids(false)
  end

  task :people => :movies do |t|
    require 'people'
    next if files_uptodate?(t, Nmdb::People.files_to_read, @files)
    puts "Doing people" if $debug
    load_movies_ids
    load_people_ids(false, previous("people_ids.dat"))
    Nmdb::People.new(input, tmp("people.build"), tmp("occupations.build"), tmp("roles.build"))
    mv tmp("people.build"), output("people.dat")
    mv tmp("occupations.build"), output("occupations.dat")
    mv tmp("roles.build"), output("roles.dat")
    if test?
      compare(output("people.dat"), expected("people.dat"))
      compare(output("occupations.dat"), expected("occupations.dat"))
    end
    load_people_ids(false)
  end

  task :plot => [:movies, :people] do |t|
    next if files_uptodate?(t, ["plot.list"], @files)
    puts "Doing plot" if $debug
    require 'plot'
    load_movies_ids
    load_people_ids
    res = Nmdb::Plot.new(input("plot.list"), tmp("plots.build"))
    mv tmp("plots.build"), output("plots.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("plots.dat"), expected("plots.dat"))
    end
  end

  task :movie_akas => :movies do |t|
    input_files = ["aka-titles.list", "iso-aka-titles.list", "german-aka-titles.list", "italian-aka-titles.list"]
    next if files_uptodate?(t, input_files, @files)
    puts "Doing movie_akas" if $debug
    require 'movie_akas'
    load_movies_ids
    res = Nmdb::MovieAkas.new(input_files.map{|x| input(x)}, tmp("movie_akas.build"))
    mv tmp("movie_akas.build"), output("movie_akas.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("movie_akas.dat"), expected("movie_akas.dat"))
    end
  end

  task :genres => :movies do |t|
    next if files_uptodate?(t, ["genres.list"], @files)
    puts "Doing genres" if $debug
    require 'genres'
    load_movies_ids
    res = Nmdb::Genres.new(input("genres.list"), tmp("genres.build"), tmp("movie_genres.build"))
    mv tmp("genres.build"), output("genres.dat")
    mv tmp("movie_genres.build"), output("movie_genres.dat")
    if test?
      raise MissedError if res.missed != 3
      compare(output("genres.dat"), expected("genres.dat"))
      compare(output("movie_genres.dat"), expected("movie_genres.dat"))
    end
  end

  task :keywords => :movies do |t|
    next if files_uptodate?(t, ["keywords.list"], @files)
    puts "Doing keywords" if $debug
    require 'keywords'
    load_movies_ids
    res = Nmdb::Keywords.new(input("keywords.list"), tmp("keywords.build"), tmp("movie_keywords.build"))
    mv tmp("keywords.build"), output("keywords.dat")
    mv tmp("movie_keywords.build"), output("movie_keywords.dat")
    if test?
      raise MissedError if res.missed != 3
      compare(output("keywords.dat"), expected("keywords.dat"))
      compare(output("movie_keywords.dat"), expected("movie_keywords.dat"))
    end
  end

  task :languages => :movies do |t|
    next if files_uptodate?(t, ["language.list"], @files)
    puts "Doing languages" if $debug
    require 'languages'
    load_movies_ids
    res = Nmdb::Languages.new(input("language.list"), tmp("languages.build"), tmp("movie_languages.build"))
    mv tmp("languages.build"), output("languages.dat")
    mv tmp("movie_languages.build"), output("movie_languages.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("languages.dat"), expected("languages.dat"))
      compare(output("movie_languages.dat"), expected("movie_languages.dat"))
    end
  end

  task :running_times => :movies do |t|
    next if files_uptodate?(t, ["running-times.list"], @files)
    puts "Doing running_times" if $debug
    require 'running_times'
    load_movies_ids
    res = Nmdb::RunningTimes.new(input("running-times.list"), tmp("running_times.build"))
    mv tmp("running_times.build"), output("running_times.dat")
    if test?
      raise MissedError if res.missed != 2
      compare(output("running_times.dat"), expected("running_times.dat"))
    end
  end

  task :complete_casts => :movies do |t|
    next if files_uptodate?(t, ["complete-cast.list"], @files)
    puts "Doing complete_casts" if $debug
    require 'complete_casts'
    load_movies_ids
    res = Nmdb::CompleteCasts.new(input("complete-cast.list"), tmp("complete_casts.build"), tmp("complete_cast_statuses.build"))
    mv tmp("complete_casts.build"), output("complete_casts.dat")
    mv tmp("complete_cast_statuses.build"), output("complete_cast_statuses.dat")
    if test?
      raise MissedError if res.missed != 2
      compare(output("complete_casts.dat"), expected("complete_casts.dat"))
    end
  end

  task :complete_crews => :movies do |t|
    next if files_uptodate?(t, ["complete-crew.list"], @files)
    puts "Doing complete_crews" if $debug
    require 'complete_crews'
    load_movies_ids
    res = Nmdb::CompleteCrews.new(input("complete-crew.list"), tmp("complete_crews.build"), tmp("complete_crew_statuses.build"))
    mv tmp("complete_crews.build"), output("complete_crews.dat")
    mv tmp("complete_crew_statuses.build"), output("complete_crew_statuses.dat")
    if test?
      raise MissedError if res.missed != 2
      compare(output("complete_crews.dat"), expected("complete_crews.dat"))
    end
  end

  task :ratings => :movies do |t|
    next if files_uptodate?(t, ["ratings.list"], @files)
    puts "Doing ratings" if $debug
    require 'ratings'
    load_movies_ids
    res = Nmdb::Ratings.new(input("ratings.list"), tmp("ratings.build"))
    mv tmp("ratings.build"), output("ratings.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("ratings.dat"), expected("ratings.dat"))
    end
  end

  task :trivia => [:movies, :people] do |t|
    next if files_uptodate?(t, ["trivia.list"], @files)
    puts "Doing trivia" if $debug
    require 'trivia'
    load_movies_ids
    res = Nmdb::Trivia.new(input("trivia.list"), tmp("trivia.build"))
    mv tmp("trivia.build"), output("trivia.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("trivia.dat"), expected("trivia.dat"))
    end
  end

  task :goofs => [:movies, :people] do |t|
    next if files_uptodate?(t, ["goofs.list"], @files)
    puts "Doing goofs" if $debug
    require 'goofs'
    load_movies_ids
    res = Nmdb::Goofs.new(input("goofs.list"), tmp("goofs.build"))
    mv tmp("goofs.build"), output("goofs.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("goofs.dat"), expected("goofs.dat"))
    end
  end

  task :person_metadata => [:movies, :people] do |t|
    next if files_uptodate?(t, ["biographies.list"], @files)
    puts "Doing person_metadata" if $debug
    require 'person_metadata'
    load_movies_ids
    load_people_ids
    res = Nmdb::PersonMetadata.new(input("biographies.list"), tmp("person_metadata.build"))
    mv tmp("person_metadata.build"), output("person_metadata.dat")
    if test?
      raise MissedError if res.missed != 0
      compare(output("person_metadata.dat"), expected("person_metadata.dat"))
    end
  end

  task :movie_connections => :movies do |t|
    next if files_uptodate?(t, ["movie-links.list"], @files)
    puts "Doing movie_connections" if $debug
    require 'movie_connections'
    load_movies_ids
    res = Nmdb::MovieConnections.new(input("movie-links.list"), tmp("movie_connections.build"), tmp("movie_connection_types.build"))
    mv tmp("movie_connections.build"), output("movie_connections.dat")
    mv tmp("movie_connection_types.build"), output("movie_connection_types.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("movie_connections.dat"), expected("movie_connections.dat"))
    end
  end

  task :release_dates => :movies do |t|
    next if files_uptodate?(t, ["release-dates.list"], @files)
    puts "Doing release_dates" if $debug
    require 'release_dates'
    load_movies_ids
    res = Nmdb::ReleaseDates.new(input("release-dates.list"), tmp("release_dates.build"))
    mv tmp("release_dates.build"), output("release_dates.dat")
    if test?
      raise MissedError if res.missed != 3
      compare(output("release_dates.dat"), expected("release_dates.dat"))
    end
  end

  task :soundtracks => [:movies, :people] do |t|
    next if files_uptodate?(t, ["soundtracks.list"], @files)
    puts "Doing soundtracks" if $debug
    require 'soundtracks'
    load_movies_ids
    load_people_ids
    res = Nmdb::Soundtracks.new(input("soundtracks.list"), tmp("soundtrack_titles.build"), tmp("soundtrack_title_data.build"))
    mv tmp("soundtrack_titles.build"), output("soundtrack_titles.dat")
    mv tmp("soundtrack_title_data.build"), output("soundtrack_title_data.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("soundtrack_titles.dat"), expected("soundtrack_titles.dat"))
      compare(output("soundtrack_title_data.dat"), expected("soundtrack_title_data.dat"))
    end
  end

  task :taglines => :movies do |t|
    next if files_uptodate?(t, ["taglines.list"], @files)
    puts "Doing taglines" if $debug
    require 'taglines'
    load_movies_ids
    res = Nmdb::Taglines.new(input("taglines.list"), tmp("taglines.build"))
    mv tmp("taglines.build"), output("taglines.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("taglines.dat"), expected("taglines.dat"))
    end
  end

  task :technicals => :movies do |t|
    next if files_uptodate?(t, ["technical.list"], @files)
    puts "Doing technicals" if $debug
    require 'technicals'
    load_movies_ids
    res = Nmdb::Technicals.new(input("technical.list"), tmp("technicals.build"))
    mv tmp("technicals.build"), output("technicals.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("technicals.dat"), expected("technicals.dat"))
    end
  end

  task :alternate_versions => [:movies, :people] do |t|
    next if files_uptodate?(t, ["alternate-versions.list"], @files)
    puts "Doing alternate_versions" if $debug
    require 'alternate_versions'
    load_movies_ids
    load_people_ids
    res = Nmdb::AlternateVersions.new(input("alternate-versions.list"), tmp("alternate_versions.build"))
    mv tmp("alternate_versions.build"), output("alternate_versions.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("alternate_versions.dat"), expected("alternate_versions.dat"))
    end
  end

  task :aka_names => :people do |t|
    next if files_uptodate?(t, ["aka-names.list"], @files)
    puts "Doing aka_names" if $debug
    require 'aka_names'
    load_people_ids
    res = Nmdb::AkaNames.new(input("aka-names.list"), tmp("aka_names.build"))
    mv tmp("aka_names.build"), output("aka_names.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("aka_names.dat"), expected("aka_names.dat"))
    end
  end

  task :certificates => :movies do |t|
    next if files_uptodate?(t, ["certificates.list"], @files)
    puts "Doing certificates" if $debug
    require 'certificates'
    load_movies_ids
    res = Nmdb::Certificates.new(input("certificates.list"), tmp("certificates.build"))
    mv tmp("certificates.build"), output("certificates.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("certificates.dat"), expected("certificates.dat"))
    end
  end

  task :color_infos => :movies do |t|
    next if files_uptodate?(t, ["color-info.list"], @files)
    puts "Doing color_infos" if $debug
    require 'color_infos'
    load_movies_ids
    res = Nmdb::ColorInfos.new(input("color-info.list"), tmp("color_infos.build"))
    mv tmp("color_infos.build"), output("color_infos.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("color_infos.dat"), expected("color_infos.dat"))
    end
  end

  task :quotes => :movies do |t|
    next if files_uptodate?(t, ["quotes.list"], @files)
    puts "Doing quotes" if $debug
    require 'quotes'
    load_movies_ids
    res = Nmdb::Quotes.new(input("quotes.list"), tmp("quotes.build"), tmp("quote_data.build"))
    mv tmp("quotes.build"), output("quotes.dat")
    mv tmp("quote_data.build"), output("quote_data.dat")
    if test?
      raise MissedError if res.missed != 1
      compare(output("quotes.dat"), expected("quotes.dat"))
      compare(output("quote_data.dat"), expected("quote_data.dat"))
    end
  end

  ns.tasks.each do |ns_task|
    next if ["build:all", "build:setup"].include?(ns_task.name)
    task :all => ns_task
  end
end

namespace "db" do |ns|
  def pg_param(optname, key)
    return [optname] if key == true
    return nil if !@pg_config[key]
    [optname, @pg_config[key]]
  end

  def pg_cmdstr(cmdkey, quiet = true)
    tmp = ([
        @pg_config[cmdkey],
        pg_param("-h", :host),
        pg_param("-p", :port),
        pg_param("-U", :user),
        pg_param("-W", :pass),
        pg_param("-q", quiet)
      ]-[nil])
    (tmp.flatten-[nil])
  end

  def pg_copy(dbname_from, dbname_to, tables)
    STDERR.puts("DEBUG: #{Time.now}: SQL-Copy: Copying from #{dbname_from} to #{dbname_to}: #{tables.inspect}") if $debug
    cmd = pg_cmdstr(:dump_cmd, false) + ["-c"]
    tables.each do |table|
      cmd += ["-t", table]
    end
    cmd += [@pg_config[dbname_from]]

    IO.popen(cmd, "r") do |io|
      pg_execute_cmd(dbname_to, io.read, false)
    end
  end

  def pg_execute_cmd(dbname, statement, stop_on_error = true)
    cmd = pg_cmdstr(:cmd) + [@pg_config[dbname]]

    IO.popen(cmd, "w") do |sql|
      sql.puts("\\set ON_ERROR_STOP true") if stop_on_error
      sql.puts(statement)
    end
    raise SQLError if !$?.success? && stop_on_error
  end

  def pg_drop_db(dbname_or_symbol)
    dbname = dbname_or_symbol
    dbname = @pg_config[dbname] if dbname.is_a?(Symbol)
    puts "DEBUG: #{Time.now}: SQL-Drop: #{dbname}" if $debug
    pg_execute_cmd(:template, "DROP DATABASE #{dbname};", false)
  end

  def pg_create_db(dbname_or_symbol)
    dbname = dbname_or_symbol
    dbname = @pg_config[dbname] if dbname.is_a?(Symbol)
    puts "DEBUG: #{Time.now}: SQL-Create: #{dbname}" if $debug
    pg_execute_cmd(:template, "CREATE DATABASE #{dbname};")
  end

  def pg_run_script(dbname, scriptfile)
    puts "DEBUG: #{Time.now}: SQL-Run: #{scriptfile}" if $debug
    pg_execute_cmd(dbname, File.read(scriptfile))
  end

  def pg_load_data(dbname, tablename, datafile)
    puts "DEBUG: #{Time.now}: SQL-Load: #{datafile}" if $debug
    statement = "COPY #{tablename} FROM '#{datafile}' DELIMITER AS '\t' NULL AS '';"
    pg_execute_cmd(dbname, statement)
  end

  def pg_rename_db(dbname_or_symbol_from, dbname_or_symbol_to, stop_on_error = true)
    dbname_from = dbname_or_symbol_from
    dbname_from = @pg_config[dbname_from] if dbname_from.is_a?(Symbol)
    dbname_to = dbname_or_symbol_to
    dbname_to = @pg_config[dbname_to] if dbname_to.is_a?(Symbol)
    puts "DEBUG: #{Time.now}: SQL-Rename: #{dbname_from} => #{dbname_to}" if $debug
    pg_execute_cmd(:template, "ALTER DATABASE #{dbname_from} RENAME TO #{dbname_to}", stop_on_error)
  end

  def pg_restart
    puts "DEBUG: #{Time.now}: SQL-Restart" if $debug
    cmd = @pg_config[:restart_cmd]
    IO.popen(cmd) {|x| x.read }
  end

  @tables = [
    "aka_names", "alternate_versions", "certificates", "color_infos",
    "complete_cast_statuses", "complete_casts", "complete_crew_statuses",
    "complete_crews", "genres", "goofs", "keywords", "languages",
    "movie_akas", "movie_connection_types", "movie_connections", "movie_genres",
    "movie_keywords", "movie_languages", "movie_years", "movies", "occupations",
    "people", "person_metadata", "plots", "quote_data", "quotes",
    "ratings", "release_dates", "roles", "running_times", "soundtrack_title_data",
    "soundtrack_titles", "taglines", "technicals", "trivia"
  ]

  task :all => :rename do
  end

  task :dump_ids => "build:setup" do
    pg_restart
    next if test? || !upgrading?
    puts "DEBUG: We're upgrading. Dump previous id's" if $debug
    # Do a select from movies and people to save id's from previous database to new build
    pwd = Dir.pwd
    dump_script = File.absolute_path(sqlscript("dump_old_ids.sql"))
    Dir.chdir(previous)
    pg_run_script(:name, dump_script)
    Dir.chdir(pwd)
  end

  task :create_temp do
    # Create temporary build database
    pg_restart
    pg_drop_db(:temp_name)
    pg_create_db(:temp_name)
    pg_run_script(:temp_name, sqlscript("dbdesign.sql"))
    pg_run_script(:temp_name, sqlscript("fuzzystrmatch.sql"))
  end

  task :copy_local_data => :create_temp do
    pg_copy(:name, :temp_name, @pg_config[:local_tables])
  end

  task :load_data => :copy_local_data do
    cleanup_ids  # No need for the build ID:s anymore.
    @tables.each do |table|
      datafile = File.absolute_path(output("#{table}.dat"))
      pg_load_data(:temp_name, table, datafile)
    end
    pg_run_script(:temp_name, sqlscript("dblink_episodes.sql"))
    pg_run_script(:temp_name, sqlscript("dbpartial_index.sql"))
    pg_run_script(:temp_name, sqlscript("prefill_tv_series.sql"))
    pg_run_script(:temp_name, sqlscript("dbindex.sql"))
  end

  task :setup_similarity => :load_data do
    # Create comparison tables for keywords, genres and languages
    # Dump them and plot data to files
    # Run overlap calculation on files
    # Load massive new file to overlap table
    # Create index for overlap table
    pg_run_script(:temp_name, sqlscript("prepare_similarity.sql"))
    pwd = Dir.pwd
    fetch_script = File.absolute_path(sqlscript("fetch_overlap_raw.sql"))
    mkdir_p overlapdata
    Dir.chdir(overlapdata)

    # Dump data from db to files.
    pg_run_script(:temp_name, fetch_script)

    Dir.chdir(pwd)
    Dir.chdir(overlap)

    puts "DEBUG: #{Time.now}: Jruby: running overlap counter..." if $debug
    # Using jruby here because jruby can properly do threading.
    system("#{@data[:jruby]} overlaps.rb")
    system("cat data/overlap_*.dat | sort -n > data/complete_overlaps.dat")

    Dir.chdir(pwd)
    pg_load_data(:temp_name, "compare_overlaps", File.absolute_path(overlapdata("complete_overlaps.dat")))

    puts "DEBUG: #{Time.now}: SQL-Index: overlap index" if $debug
    pg_execute_cmd(:temp_name, "CREATE INDEX compare_overlaps_idx_movie_id ON compare_overlaps(movie_id);")
  end

  task :setup_sphinx => :setup_similarity do
    # Alter movie_connections to include link weights
    # Create sphinx tables
    # Create sphinx views using sphinx tables
    pg_run_script(:temp_name, sqlscript("sphinx_tables.sql"))
    pg_run_script(:temp_name, sqlscript("sphinx_views.sql"))
  end

  task :setup_suggestions => :setup_sphinx do
    # Create tables used for suggestions
    pg_run_script(:temp_name, sqlscript("suggestions.sql"))
  end

  task :rename => :setup_suggestions do
    pg_restart
    pg_drop_db(:old_name)
    pg_rename_db(:name, :old_name, false) # We do not have to have a database before.
    pg_rename_db(:temp_name, :name)
  end
end

