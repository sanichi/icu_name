module ICU
  class Util
    # Decide if a string is valid UTF-8 or not, returning true or false.
    def self.is_utf8(str)
      dup = str.dup
      dup.force_encoding("UTF-8")
      dup.valid_encoding?
    end
    
    # Try to convert any string to UTF-8.
    def self.to_utf8(str)
      utf8 = is_utf8(str)
      dup = str.dup
      return dup.force_encoding("UTF-8") if utf8
      dup.force_encoding("Windows-1252") if dup.encoding.name.match(/^(ASCII-8BIT|UTF-8)$/)
      dup.encode("UTF-8")
    end
  end
end