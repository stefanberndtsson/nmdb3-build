module Nmdb
  class People
    def self.get_id(person_obj)
      if @@people_ids[person_obj.full_name]
        return @@people_ids[person_obj.full_name]
      elsif @@people_ids[person_obj.reverse_name(true, true)]
        return @@people_ids[person_obj.reverse_name(true, true)]
      else
        @@max_id += 1
        new_id = @@max_id
        @@people_ids[person_obj.full_name] = new_id
        @@people_ids[person_obj.reverse_name(true, true)] = new_id
        @@people_ids[person_obj.reverse_name] = new_id
        return new_id
      end
    end

    def self.lookup_id(name)
      return @@people_ids[name]
    end

    def self.get_occupations_id
      @@max_occupations_id += 1
      new_id = @@max_occupations_id
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
      STDERR.puts("#{Time.now}:  - getting names") if $debug
      names = values.transpose[1]
      STDERR.puts("#{Time.now}:  - setting ids to numeric") if $debug
      ids = values.transpose[0].map{|x| x.to_i}
      values = nil
#      GC.enable
      GC.start
#      GC.disable
      STDERR.puts("#{Time.now}:  - creating Hash") if $debug
      @@people_ids = Hash[names.zip(ids)]
      STDERR.puts("#{Time.now}:  - getting highest id") if $debug
      @@max_id = ids.max
      STDERR.puts("#{Time.now}:  - reversing and hashing names") if $debug
      names.each_with_index do |name,i|
        @@people_ids[reverse_name(name)] = ids[i]
        @@people_ids[reverse_name(name, true, true)] = ids[i]
      end
      names = nil
#      GC.enable
      GC.start
      STDERR.puts("#{Time.now}:  - done") if $debug
      @@loaded = true
    end

    def self.setup_ids
      if defined?(@@people_ids)
        @@people_ids.each do |key,val|
          @@people_ids.delete(key)
        end
        GC.start
      end
      @@people_ids = {}
      @@max_id = 0
      @@max_occupations_id = 0
      @@loaded = false
    end
  end
end

#if File.exist?(LOAD_PEOPLE_IDS_FILE)
#  Nmdb::People.load_ids(LOAD_PEOPLE_IDS_FILE)
#else
#  Nmdb::People.setup_ids
#end
