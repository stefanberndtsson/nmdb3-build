module Nmdb
  class Movies
    def self.get_id(movie_obj)
      if @@movies_ids[movie_obj.full_title]
        return @@movies_ids[movie_obj.full_title]
      elsif @@movies_ids[movie_obj.split_title_data(true)]
        return @@movies_ids[movie_obj.split_title_data(true)]
      else
        @@max_id += 1
        new_id = @@max_id
        @@movies_ids[movie_obj.full_title] = new_id
        @@movies_ids[movie_obj.split_title_data(true)] = new_id
        return new_id
      end
    end

    def self.lookup_id(title)
      return @@movies_ids[title]
    end

    def self.get_years_id
      @@max_years_id += 1
      new_id = @@max_years_id
      return new_id
    end

    def self.load_ids(filename, skip_if_loaded = false)
      return if defined?(@@loaded) && @@loaded && skip_if_loaded
      setup_ids
#      GC.disable
      STDERR.puts("#{Time.now}: Loading #{filename}") if $debug
      values = File.read(filename).split(/\n/).map {|x| x.split(/\t/, -1)}
      if values.empty?
        @@loaded = true
        return
      end
      STDERR.puts("#{Time.now}:  - getting titles") if $debug
      titles = values.transpose[1]
      STDERR.puts("#{Time.now}:  - setting ids to numeric") if $debug
      ids = values.transpose[0].map{|x| x.to_i}
      values = nil
#      GC.enable
      GC.start
#      GC.disable
      STDERR.puts("#{Time.now}:  - creating Hash") if $debug
      @@movies_ids = Hash[titles.zip(ids)]
      STDERR.puts("#{Time.now}:  - getting highest id") if $debug
      @@max_id = ids.max
      STDERR.puts("#{Time.now}:  - splitting and hashing titles") if $debug
      titles.each_with_index do |title,i|
        @@movies_ids[split_title(title, true)] = ids[i]
      end
      titles = nil
#      GC.enable
      GC.start
      STDERR.puts("#{Time.now}:  - done") if $debug
      @@loaded = true
    end

    def self.setup_ids
      if defined?(@@movies_ids)
        @@movies_ids.each do |key,val|
          @@movies_ids.delete(key)
        end
        GC.start
      end
      @@movies_ids = {}
      @@max_id = 0
      @@max_years_id = 0
      @@loaded = false
    end
  end
end

#if Object.const_defined?("LOAD_MOVIES_IDS_FILE") && File.exist?(LOAD_MOVIES_IDS_FILE)
#  Nmdb::Movies.load_ids(LOAD_MOVIES_IDS_FILE)
#else
#  Nmdb::Movies.setup_ids
#end
