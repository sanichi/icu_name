require 'active_support'
require 'active_support/inflector/transliterate'
require 'active_support/core_ext/string/multibyte'

module ICU
  class Name

    # Construct from one or two strings or any objects that have a to_s method.
    def initialize(name1='', name2='', opt={})
      @name1 = Util.to_utf8(name1.to_s)
      @name2 = Util.to_utf8(name2.to_s)
      canonicalize
      if opt[:ascii]
        @first = ActiveSupport::Inflector.transliterate(@first)
        @last  = ActiveSupport::Inflector.transliterate(@last)
      end
    end

    # First name getter.
    def first(opts={})
      return ActiveSupport::Inflector.transliterate(@first) if opts[:ascii]
      @first
    end

    # Last name getter.
    def last(opts={})
      return ActiveSupport::Inflector.transliterate(@last) if opts[:ascii]
      @last
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

    # Convert object to a string.
    def to_s(opts={})
      rname(opts)
    end

    # Match another name to this object, returning true or false.
    def match(name1='', name2='', opts={})
      other = Name.new(name1, name2, opts)
      match_first(first(opts), other.first) && match_last(last(opts), other.last)
    end

    # :stopdoc:
    private

    # Canonicalise the first and last names.
    def canonicalize
      first, last = partition
      @first = finish_first(first)
      @last  = finish_last(last)
    end

    # Split one complete name into first and last parts.
    def partition
      if @name2.length == 0
        # Only one imput so we must split first and last.
        parts = @name1.split(/,/)
        if parts.size > 1
          last  = clean(parts.shift || '')
          first = clean(parts.join(' '))
        else
          parts = clean(@name1).split(/ /)
          last  = parts.pop || ''
          last  = "#{parts.pop}'#{last}" if parts.size > 1 && parts.last == "O" && !last.match(/^O'/)
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
      name.gsub!(/`/, "'")
      name.gsub!(/[^-a-zA-Z\u{c0}-\u{d6}\u{d8}-\u{f6}\u{f8}-\u{ff}.'\s]/, '')
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

    # Apply final touches to finish canonicalising a first name mb_chars object, returning a normal string.
    def finish_first(names)
      names.gsub(/([A-Z\u{c0}-\u{de}])\b/, '\1.')
    end

    # Apply final touches to finish canonicalising a last name mb_chars object, returning a normal string.
    def finish_last(names)
      names.gsub!(/\b([A-Z\u{c0}-\u{de}]')([a-z\u{e0}-\u{ff}])/) { |m| $1 << $2.mb_chars.upcase.to_s }
      names.gsub!(/\b(Mc)([a-z\u{e0}-\u{ff}])/) { |m| $1 << $2.mb_chars.upcase.to_s }
      names.gsub!(/\bO ([A-Z\u{c0}-\u{de}])/) { |m| "O'" << $1 }
      names
    end

    # Match a complete first name.
    def match_first(first1, first2)
      # Is this one a walk in the park?
      return true if first1 == first2

      # No easy ride. Begin by splitting into individual first names.
      first1 = split_first(first1)
      first2 = split_first(first2)

      # Get the long list and the short list.
      long, short = first1.size >= first2.size ? [first1, first2] : [first2, first1]

      # The short one must be a "subset" of the long one.
      # An extra condition must also be satisfied.
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
      return initials if first1 == first2
      return 0 if initials == 0 && match_nick_name(first1, first2)
      return -1 unless initials > 0
      return initials if first1[0] == first2[0]
      -1
    end

    # Match two first names that might be equivalent nicknames.
    def match_nick_name(nick1, nick2)
      compile_nick_names unless @@nc
      code1 = @@nc[nick1]
      return false unless code1
      code1 == @@nc[nick2]
    end

    # Compile the nick names code hash when matching nick names is first attempted.
    def compile_nick_names
      @@nc = Hash.new
      code = 1
      @@nl.each do |nicks|
        nicks.each do |n|
          throw "duplicate name #{n}" if @@nc[n]
          @@nc[n] = code
        end
        code+= 1
      end
    end

    # A array of data for matching nicknames and also a few common misspellings.
    @@nc = nil
    @@nl = <<EOF.split(/\n/).reject{|x| x.length == 0 }.map{|x| x.split(' ')}
Abdul Abul
Alexander Alex
Anandagopal Ananda
Anne Ann
Anthony Tony
Benjamin Ben
Catherine Cathy Cath
Daniel Danial Danny Dan
David Dave
Deborah Debbie
Des Desmond
Eamonn Eamon
Edward Eddie Ed
Eric Erick Erik
Frederick Frederic Fred
Gerald Gerry
Gerhard Gerard Ger
James Jim
Joanna Joan Joanne
John Johnny
Jonathan Jon
Kenneth Ken Kenny
Michael Mike Mick Micky
Nicholas Nick Nicolas
Nicola Nickie Nicky
Patrick Pat Paddy
Peter Pete
Philippe Philip Phillippe Phillip
Rick Ricky
Robert Bob Bobby
Samual Sam Samuel
Stefanie Stef
Stephen Steven Steve
Terence Terry
Thomas Tom Tommy
William Will Willy Willie Bill
EOF
  end
end
