# require 'unicode_utils'

#class String
#  def norm
#    decomposed = UnicodeUtils.nfkd(self)
#    downcased = UnicodeUtils.downcase(decomposed)
#    downcased.split("").select { |x| x < "\u{100}" }.join
#  end
#end

def load_data(filename)
  output = { }
  File.open(filename, "rb").each_line do |line|
    tmp3 = nil
    movie_id,tmp = line.chomp.split("\t")
    tmp3 = tmp.gsub(/[{}]/,"").split(",").map { |x| x.downcase.gsub("-", " ").gsub(/[^ a-z0-9]/, "") }.sort
    output[movie_id.to_i] = tmp3 || []
  end
  return output
end

def load_active(filename)
  return File.open(filename, "rb").read.split(/\n/).map { |x| x.downcase.gsub("-", " ").gsub(/[^ a-z0-9]/, "") }.sort
end

def load_plot(filename)
  output = { }
  File.open(filename, "rb").each_line do |line|
    tmp3 = nil
    movie_id,tmp = line.chomp.split("\t")
    begin
      tmp3 = tmp.downcase.gsub("-", " ").gsub(/[^ a-z0-9]/, "")
    rescue
      tmp3 = nil
    end
    if tmp3
      output[movie_id.to_i] ||= []
      output[movie_id.to_i] << tmp3
    end
  end

  output2 = { }
  output.keys.each do |movie_id|
    cache = { }
    output2[movie_id] = { }
    tmp3 = output[movie_id].join(" ")
    tmp3.split(" ").each do |word|
      cache[word] = tmp3
    end
    output2[movie_id] = { :plot => tmp3, :cache => cache }
  end
  return output2
end

def load_strong(keywords, plots)
  output = { }
  keywords.keys.each do |movie_id|
    if (!plots[movie_id] || !plots[movie_id][:plot]) || keywords[movie_id].empty?
      output[movie_id] = []
      next
    end
    skws = []
    keywords[movie_id].each do |kw|
      next if !plots[movie_id][:cache][kw]
      if plots[movie_id][:plot].my_index(kw)
        skws << kw
      end
    end
    output[movie_id] = skws.uniq || []
  end
  return output
end

