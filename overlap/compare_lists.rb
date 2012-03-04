class Array
  def permute(prefixed=[])
    if (length < 2)
      # there are no elements left to permute
      yield(prefixed + self)
    else
      # recursively permute the remaining elements
      each_with_index do |e, i|
        (self[0,i]+self[(i+1)..-1]).permute(prefixed+[e]) { |a| yield a }
      end
    end
  end
end

class String
  def my_index(needle)
    self.index(needle)
#    self[/needle/]
  end
end

def compare_lists(file, mids, kw, gw, lw, pl, skw)
  mids.each do |movie_id|
    kw.keys.each do |compare_movie_id|
      next if movie_id >= compare_movie_id
      cp = compare_all(movie_id, compare_movie_id, kw, gw, lw, pl, skw)
      next if !cp
      cp2 = [cp[0], cp[2], cp[1], cp[3], cp[4], cp[5]]
      file.puts(([movie_id, compare_movie_id] + cp).join("\t"))
      file.puts(([compare_movie_id, movie_id] + cp2).join("\t"))
    end
  end
end

def compare_all(movie_id, compare_movie_id, kw, gw, lw, pl, skw)
  ckw = compare_keywords(movie_id, compare_movie_id, 
                         kw[movie_id], kw[compare_movie_id], skw[movie_id], skw[compare_movie_id])
  return nil if !ckw
  cgw = (gw[movie_id] & gw[compare_movie_id]).size
  clw = (lw[movie_id] & lw[compare_movie_id]).size
  return [ckw, cgw, clw].flatten
end

def compare_keywords(movie_id, compare_movie_id, srckws, dstkws, src_strong, dst_strong)
  n_n = (srckws & dstkws).size
  return nil if n_n == 0
  n_s = (srckws & dst_strong).size
  s_n = (src_strong & dstkws).size
  s_s = (src_strong & dst_strong).size
  return [n_n, n_s, s_n, s_s]
end

def strong_keywords(movie_id, keywords, plots, cache)
  if cache[movie_id]
    return cache[movie_id]
  end
  if (!plots || !plots[:plot]) || keywords.empty?
    cache[movie_id] = []
    return []
  end
  output = []
  keywords.each do |kw|
    next if !plots[:cache][kw]
    if plots[:plot].my_index(kw)
      output << kw
    end
  end
  cache[movie_id] = output.uniq
  return output.uniq
end

def strong_keywords_perm(keywords, plots)
  return [] if !plots || plots.empty?
  return [] if keywords.empty?
  pl = plots.join(" ")
  output = []
  keywords.each do |kw|
    kw.split(" ").permute do |tmp|
      pkw = tmp.join(" ")
      if pl.index(pkw)
        output << kw
      end
    end
  end
  return output.uniq
end
