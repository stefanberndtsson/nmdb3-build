#!/usr/bin/env ruby

$: << "."

require 'compare_lists'
require 'loaddata'

strongcache = { }
@akw = load_active("data/active_keywords.dat")
@kw = load_data("data/full_keyword.dat")
@gw = load_data("data/full_genre.dat")
@lw = load_data("data/full_language.dat")
@pl = load_plot("data/full_plot.dat")

@skw = load_strong(@kw, @pl)

before = 0
after = 0
total = @kw.keys.size
deleted = 0
@kw.keys.each do |movie_id|
  before += @kw[movie_id].size
  @kw[movie_id] = @kw[movie_id] & @akw
  after += @kw[movie_id].size
  if @kw[movie_id].size < 4
    @kw.delete(movie_id)
    deleted += 1
  end
end

parts = 4
psize = @kw.keys.size/parts
lists = []
files = []

parts.times do |part|
  if part == parts-1
    lists << @kw.keys.sort[psize*part..-1]
  else
    lists << @kw.keys.sort[psize*part..(psize*(part+1)-1)]
  end
  files << File.open("data/overlap_#{part}.dat", "wb")
end

running = true

threadless = false

if threadless
  start = Time.now()
  lists.each_with_index do |list,i|
    compare_lists(files[i], list, @kw, @gw, @lw, @pl, @skw)
  end
else
  strongcache = []
  thr = []

  lists.each_with_index do |list,i|
    strongcache[i] = { }
    thr << Thread.new { compare_lists(files[i], list, @kw, @gw, @lw, @pl, @skw) }
  end
  start = Time.now()
  while running
    sleep 0.2
    running = false
    thr.each do |thread|
      if thread.alive?
        running = true
        break
      end
    end
  end
end
stop = Time.now()
total_time = stop.to_f-start.to_f
speed = (psize*parts).to_f/total_time

