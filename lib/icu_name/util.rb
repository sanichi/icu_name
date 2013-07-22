# encoding: UTF-8

module ICU
  module Util
    LOWER_CHARS      = "àáâãäåæçèéêëìíîïñòóôõöøùúûüýþ"
    UPPER_CHARS      = "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÑÒÓÔÕÖØÙÚÛÜÝÞ"
    ACCENTED_CHARS   = "ÀÁÂÃÄÅÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝàáâãäåèéêëìíîïñòóôõöùúûüý"
    UNACCENTED_CHARS = "AAAAAAEEEEIIIINOOOOOUUUUYaaaaaaeeeeiiiinooooouuuuy"

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

    # Upcase a UTF-8 string that might contain accented characters.
    def self.upcase(str)
      str = str.upcase
      return str if str.ascii_only?
      str.tr(LOWER_CHARS, UPPER_CHARS)
    end

    # Downcase a UTF-8 string that might contain accented characters.
    def self.downcase(str)
      str = str.downcase
      return str if str.ascii_only?
      str.tr(UPPER_CHARS, LOWER_CHARS)
    end
    
    # Capilalize a UTF-8 string that might contain accented characters.
    def self.capitalize(str)
      return str.capitalize if str.ascii_only? || !str.match(/\A(.)(.*)\z/)
      upcase($1) + downcase($2)
    end
    
    # Transliterate Latin-1 accented characters to ASCII.
    def self.transliterate(str)
      return str.dup if str.ascii_only?
      str.tr(ACCENTED_CHARS, UNACCENTED_CHARS)
    end
  end
end