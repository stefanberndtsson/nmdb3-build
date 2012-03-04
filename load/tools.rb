require 'unicode'
require 'unicode_utils'

module UnicodeUtils
  def compatibility_decompositionx(str)
    res = String.new.force_encoding(str.encoding)
    str.each_codepoint { |cp|
      Impl.append_recursive_compatibility_decomposition_mappingx(res, cp)
    }
#    Impl.put_into_canonical_order(res)
    res
  end

  module_function :compatibility_decompositionx

  module Impl # :nodoc:

    def self.append_recursive_compatibility_decomposition_mappingx(str, cp)
      mapping = COMPATIBILITY_DECOMPOSITION_MAP[cp]
      mapping ||= CANONICAL_DECOMPOSITION_MAP[cp]
      if !mapping
        str << cp if cp < 0x100
      else
        mapping.each { |c|
          append_recursive_compatibility_decomposition_mappingx(str, c)
        }
      end
    end

  end
end

class String
  def norm_old
    decomposed = UnicodeUtils.compatibility_decompositionx(self)
    UnicodeUtils.downcase(decomposed)
  end

  def norm
    decomposed = Unicode.nfkd(self).gsub(/[^\u0000-\u00ff]/, "")
    Unicode.downcase(decomposed)
  end

  def trim
    self.gsub(/\s+$/,"").gsub(/^\s+/,"")
  end

  def hardtrim
    self.gsub(/^[^a-z0-9\"]+/,"").gsub(/[^a-z0-9\"]+$/,"").gsub(/^\"\"$/,"")
  end
end

class NilClass
  def norm
    nil
  end
end

class Array
  def detab
    self.collect! {|x| x.kind_of?(String) ? x.gsub(/\s*\t\s*/," ").gsub(/\\/,"\\\\\\").trim : x }
  end
end
