require 'movies'

module Nmdb
  class Certificates
    attr_reader :missed

    IGNORE_BEFORE="CERTIFICATES LIST"
    IGNORE_AFTER=1
    DONE_AT="----------------------------"

    def initialize(input_file, certificates_file)
      @certificates_output = File.open(certificates_file, "w")
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
      @certificates_output.close
    end

    def parse_line(line)
      return if line[/^\s*$/]

      name,data,@info = line.split(/\t+/)

      @movie_id = Movies.lookup_id(name)
      if !@movie_id
        @missed += 1
        return
      end

      return if !data || data.empty?

      country,*cert = data.split(":")
      if cert.empty?
        @certificate = country
        @country = nil
      else
        @certificate = cert.join(":")
        @country = country
      end

      return if !@certificate || @certificate.empty?

      output_certificates_line(@certificates_output)
    end

    def output_certificates_line(output_file)
      @certificate_id = get_id
      line = [@certificate_id, @movie_id, @country, @certificate, @info].detab.join("\t")
      output_file.puts(line)
    end

    def get_id
      @max_id += 1
      return @max_id
    end
  end
end
