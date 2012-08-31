# encoding: UTF-8
require 'active_support'
require 'active_support/inflector/transliterate'
require 'active_support/core_ext/string/multibyte'

module ICU
  class Name
    # Revert to the default sets of alternative names.
    def self.reset_alternatives
      @@alts = Hash.new
      @@cmps = Hash.new
    end

    # Perform a reset when the class is first loaded.
    self.reset_alternatives

    # Construct a new name from one or two strings or any objects that have a to_s method.
    def initialize(name1='', name2='')
      @name1 = Util.to_utf8(name1.to_s)
      @name2 = Util.to_utf8(name2.to_s)
      originalize
      canonicalize
      repair
      @first.freeze
      @last.freeze
      @original.freeze
    end

    # Original text getter.
    def original(opts={})
      return transliterate(@original, opts[:chars]) if opts[:chars]
      @original.dup
    end

    # First name getter.
    def first(opts={})
      return transliterate(@first, opts[:chars]) if opts[:chars]
      @first.dup
    end

    # Last name getter.
    def last(opts={})
      return transliterate(@last, opts[:chars]) if opts[:chars]
      @last.dup
    end

    # Return a complete name, first name first, no comma.
    def name(opts={})
      name = ''
      name << first(opts)
      name << ' ' if @first.length > 0 && @last.length > 0
      name << last(opts)
      name
    end

    # Return a reversed complete name, first name last after a comma.
    def rname(opts={})
      name = ''
      name << last(opts)
      name << ', ' if @first.length > 0 && @last.length > 0
      name << first(opts)
      name
    end

    # Convert to a string (same as rname).
    def to_s(opts={})
      rname(opts)
    end

    # Match another name to this object, returning true or false.
    def match(name1='', name2='', opts={})
      other = Name.new(name1, name2)
      match_first(first(opts), other.first(opts)) && match_last(last(opts), other.last(opts))
    end

    # Load a set of first or last name alternatives. If the YAML file name is absent,
    # the default set is loaded. <tt>type</tt> should be <tt>:first</tt> or <tt>:last</tt>.
    def self.load_alternatives(type, file=nil)
      compile_alts(check_type(type), file, true)
    end

    # Show first name or last name alternatives.
    def alternatives(type)
      get_alts(check_type(type))
    end

    # :stopdoc:
    private

    # Save the original inputs without any cleanup other than whitespace.
    def originalize
      @original = @name2 == '' ? @name1.clone : "#{@name2.strip}, #{@name1.strip}"
      @original.strip!
      @original.gsub!(/\s+/, ' ')
    end

    # Transliterate characters to ASCII or Latin1.
    def transliterate(str, chars='US-ASCII')
      case chars
      when /^(US-?)?ASCII/i
        ActiveSupport::Inflector.transliterate(str)
      when /^(Windows|CP)-?1252|ISO-?8859-?1|Latin(-?1)?$/i
        str.gsub(/./) { |m| m.ord < 256 ? m : ActiveSupport::Inflector.transliterate(m) }
      else
        str.dup
      end
    end

    # Canonicalise the first and last names.
    def canonicalize
      first, last = partition
      @first = finish_first(first)
      @last  = finish_last(last)
    end

    # Split one complete name into first and last parts.
    def partition
      if @name2.length == 0
        # Only one input so we must split it into first and last.
        parts = @name1.split(/,/)
        if parts.size > 1
          last  = clean(parts.shift || '')
          first = clean(parts.join(' '))
        else
          parts = clean(@name1).split(/ /)
          last  = parts.pop || ''
          last  = "#{parts.pop}'#{last}" if parts.size > 1 && parts.last.match(/^O$/i) && !last.match(/^O'/i)  # "O", "Reilly" => "O'Reilly"
          first = parts.join(' ')
        end
      else
        # Two inputs, so we are given first and last.
        first = clean(@name1)
        last  = clean(@name2)
      end
      [first, last]
    end

    # Clean up characters in any name keeping only letters (including accented), hyphens, and single quotes.
    def clean(name)
      name.gsub!(/[`‘’′‛]/, "'")
      name.gsub!(/./) do |m|
        if m.ord < 256
          # Keep Latin1 accented letters.
          m.match(/^[-a-zA-Z\u{c0}-\u{d6}\u{d8}-\u{f6}\u{f8}-\u{ff}.'\s]$/) ? m : ''
        else
          # Keep ASCII characters with diacritics (e.g. Polish ł and Ś).
          transliterate(m) == '?' ? '' : m
        end
      end
      name.gsub!(/\./, ' ')
      name.gsub!(/\s*-\s*/, '-')
      name.gsub!(/'+/, "'")
      name.strip.mb_chars.downcase.split(/\s+/).map do |n|
        n.sub!(/^-+/, '')
        n.sub!(/-+$/, '')
        n.split(/-/).map do |p|
          p.capitalize!
        end.join('-')
      end.join(' ').to_s
    end
    
    # Try to ensure the encoding is UTF-8. This wasn't necessary before but some upgrade caused a change
    # in behaviour. Since UTF-8 and ASCII are compatible encodings, it's probably not necessary to do
    # this but I like to keep everything in the same encoding.
    def repair
      @first.force_encoding('UTF-8') if @first.encoding.name == "US-ASCII"
      @last.force_encoding('UTF-8')  if @last.encoding.name == "US-ASCII"
    end

    # Apply final touches to finish canonicalising a first name mb_chars object, returning a normal string.
    def finish_first(names)
      names.gsub(/([A-Z\u{c0}-\u{de}])\b/, '\1.')
    end

    # Apply final touches to finish canonicalising a last name mb_chars object, returning a normal string.
    def finish_last(names)
      names.gsub!(/\b([A-Z\u{c0}-\u{de}]')([a-z\u{e0}-\u{ff}])/) { |m| $1 << $2.mb_chars.upcase.to_s }
      names.gsub!(/\b(Mc)([a-z\u{e0}-\u{ff}])/) { |m| $1 << $2.mb_chars.upcase.to_s }
      names.gsub!(/\bMac([a-z\u{e0}-\u{ff}])/) do |m|
        letter = $1  # capitalize after "Mac" only if the original clearly indicates it
        upper = letter.mb_chars.upcase.to_s
        'Mac'.concat(@original.match(/\bMac#{upper}/) ? upper : letter)
      end
      names.gsub!(/\bO ([A-Z\u{c0}-\u{de}])/) { |m| "O'" << $1 }
      names
    end

    # Check the type argument to the public methods.
    def check_type(type) self.class.instance_eval { check_type(type) }; end
    def self.check_type(type) type = type.to_s == "last" ? :last : :first; end

    # Match a complete first name.
    def match_first(first1, first2)
      # Is this one a walk in the park?
      return true if first1 == first2

      # No easy ride. Begin by splitting into individual first names.
      first1 = split_first(first1)
      first2 = split_first(first2)

      # Get the long list and the short list.
      long, short = first1.size >= first2.size ? [first1, first2] : [first2, first1]

      # The short one must be a "subset" of the long one. An extra condition must also be satisfied:
      # either there has to be at least one match not involving initials or the first names must match.
      # For example "M. J." matches "Mark" but not  "John".
      extra = false
      (0..long.size-1).each do |i|
        lword = long.shift
        score = match_first_name(lword, short.first)
        if score >= 0
          short.shift
          extra = true if i == 0 || score == 0
        end
        break if short.empty? || long.empty?
      end

      # There's a match if the following is true.
      short.empty? && extra
    end

    # Match a complete last name.
    def match_last(last1, last2)
      return true if last1 == last2
      return true if match_alt(:last, last1, last2)
      [last1, last2].each do |last|
        last.downcase!            # case insensitive
        last.gsub!(/\bmac/, 'mc') # MacDonaugh and McDonaugh
        last.tr!('-', ' ')        # Lowry-O'Reilly and Lowry O'Reilly
      end
      last1 == last2
    end

    # Split a complete first name for matching.
    def split_first(first)
      first.tr!('-', ' ')              # J. K. and J.-K.
      first = first.split(/ /)         # split on spaces
      first = [''] if first.size == 0  # in case input was empty string
      first
    end

    # Match individual first names or initials.
    # -1 = no match
    #  0 = full match
    #  1 = match involving 1 initial
    #  2 = match involving 2 initials
    def match_first_name(first1, first2)
      initials = 0
      initials+= 1 if first1.match(/^[A-Z\u{c0}-\u{de}]\.?$/)
      initials+= 1 if first2.match(/^[A-Z\u{c0}-\u{de}]\.?$/)
      return initials if first1 == first2                             # "W." and "W." or "William" and "William"
      return 0 if initials == 0 && match_alt(:first, first1, first2)  # "William"" and "Bill"
      return -1 unless initials > 0                                   # "William" and "Patricia"
      return initials if first1[0] == first2[0]                       # "W." and "William" or "W." and "W"
      -1
    end

    # Match two names that might be equivalent due to nicknames, misspellings, changed married names etc.
    def match_alt(type, nam1, nam2)
      self.class.compile_alts(type)
      return false unless nams = @@alts[type][nam1]
      return false unless cond = nams[nam2]
      return true if cond == true
      cond.match(type == :first ? @last : @first)
    end

    # Return an array of alternative first or second names (not including the original name).
    # Allow for double barrelled last names or multiple first names.
    def get_alts(type)
      self.class.compile_alts(type)
      name = self.send(type)
      names = name.split(/[- ]/)
      names.push(name) if names.length > 1
      target = type == :first ? @last : @first
      alts = Array.new
      names.each do |n|
        next unless @@alts[type][n]
        @@alts[type][n].each_pair do |k, v|
          alts.push k if v == true || v.match(target)
        end
      end
      alts.concat(automatic_alts(names))
      alts
    end
    
    # Add automatic alternatives - those not dependent on a compiled list.
    # Currently only provides alternative for apostrophes, as backticks are often used instead by FIDE.
    def automatic_alts(names)
      names.find_all{|n| n.index("'")}.map{|n| n.gsub!("'", "`")}
    end

    # Compile an alternative names hash (for either first names or last names) before matching is first attempted.
    def self.compile_alts(type, data=nil, force=false)
      return if @@alts[type] && !force
      unless data
        file = File.expand_path(File.dirname(__FILE__) + "/../../config/#{type}_alternatives.yaml")
        data = File.open(file) { |fd| YAML.load(fd) }
      end
      @@cmps[type] ||= 0
      @@alts[type] = Hash.new
      code = 1
      data.each do |alts|
        cond = true
        alts.reject! do |a|
          if a.instance_of?(Regexp)
            cond = a
          else
            false
          end
        end
        alts.each do |name|
          alts.each do |other|
            unless other == name
              @@alts[type][name] ||= Hash.new
              @@alts[type][name][other] = cond
            end
          end
        end
        code+= 1
      end
      @@cmps[type] += 1
    end

    # Return the number of YAML file compilations (for testing).
    def self.alt_compilations(type)
      @@cmps[check_type(type)] || 0
    end
  end
end
