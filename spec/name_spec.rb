# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  describe Name do
    def load_alt_test(reset, *types)
      Name.reset_alternatives if reset
      types.each do |type|
        file = File.expand_path(File.dirname(__FILE__) + "/../config/test_#{type}_alts.yaml")
        data = File.open(file) { |fd| YAML.load(fd) }
        Name.load_alternatives(type, data)
      end
    end

    def alt_compilations(type)
      Name.alt_compilations(type)
    end

    context "public methods" do
      before(:each) do
        @simple = Name.new('mark j l', 'ORR')
      end

      it "#first returns the first name(s)" do
        expect(@simple.first).to eq('Mark J. L.')
      end

      it "#last returns the last name(s)" do
        expect(@simple.last).to eq('Orr')
      end

      it "#name returns the full name with first name(s) first" do
        expect(@simple.name).to eq('Mark J. L. Orr')
      end

      it "#rname returns the full name with last name(s) first" do
        expect(@simple.rname).to eq('Orr, Mark J. L.')
      end

      it "#to_s is the same as rname" do
        expect(@simple.to_s).to eq('Orr, Mark J. L.')
      end

      it "#original returns the original data" do
        expect(@simple.original).to eq('ORR, mark j l')
      end

      it "#match returns true if and only if two names match" do
        expect(@simple.match('mark j l orr')).to be_truthy
        expect(@simple.match('malcolm g l orr')).to be_falsey
      end
    end

    context "rdoc expample" do
      before(:each) do
        @robert = Name.new(' robert  j ', ' FISCHER ')
        @bobby = Name.new(' bobby fischer ')
      end

      it "should get Robert" do
        expect(@robert.name).to eq('Robert J. Fischer')
      end

      it "should get Bobby" do
        expect(@bobby.last).to eq('Fischer')
        expect(@bobby.first).to eq('Bobby')
      end

      it "should match Robert and Bobby" do
        expect(@robert.match(@bobby)).to be_truthy
        expect(@robert.match('R. J.', 'Fischer')).to be_truthy
        expect(@bobby.match('R. J.', 'Fischer')).to be_falsey
      end

      it "should canconicalise last names" do
        expect(Name.new('John', 'O Reilly').last).to eq("O'Reilly")
        expect(Name.new('dave', 'mcmanus').last).to eq("McManus")
        expect(Name.new('pete', 'MACMANUS').last).to eq("Macmanus")
      end

      it "characters and encoding" do
        expect(ICU::Name.new('éric', 'PRIÉ').name).to eq("Éric Prié")
        expect(ICU::Name.new('BARTŁOMIEJ', 'śliwa').name).to eq("Bartomiej Liwa")
        expect(ICU::Name.new('Սմբատ', 'Լպուտյան').name).to eq("")
        eric = Name.new('éric'.encode("ISO-8859-1"), 'PRIÉ'.force_encoding("ASCII-8BIT"))
        expect(eric.rname).to eq("Prié, Éric")
        expect(eric.rname.encoding.name).to eq("UTF-8")
        expect(eric.original).to eq("PRIÉ, éric")
        expect(eric.original.encoding.name).to eq("UTF-8")
        expect(eric.rname(:chars => "US-ASCII")).to eq("Prie, Eric")
        expect(eric.original(:chars => "US-ASCII")).to eq("PRIE, eric")
        expect(eric.match('Éric', 'Prié')).to be_truthy
        expect(eric.match('Eric', 'Prie')).to be_falsey
        expect(eric.match('Eric', 'Prie', :chars => "US-ASCII")).to be_truthy
      end
    end

    context "names that are already canonical" do
      it "should not be altered" do
        expect(Name.new('Mark J. L.', 'Orr').name).to eq('Mark J. L. Orr')
        expect(Name.new('Anna-Marie J.-K.', 'Liviu-Dieter').name).to eq('Anna-Marie J.-K. Liviu-Dieter')
        expect(Name.new('Èric Cantona').name).to eq('Èric Cantona')
      end
    end

    context "last names involving single quote-like characters" do
      before(:each) do
        @una = Name.new('Una', "O'Boyle")
      end

      it "should use apostrophe (0027) as the canonical choice" do
        expect(Name.new('una', "O'boyle").name).to eq("Una O'Boyle")
        expect(Name.new('Una', "o’boyle").name).to eq("Una O'Boyle")
        expect(Name.new('jonathan', 'd`arcy').name).to eq("Jonathan D'Arcy")
        expect(Name.new('erwin e', "L′AMI").name).to eq("Erwin E. L'Ami")
        expect(Name.new('cormac', "o brien").name).to eq("Cormac O'Brien")
        expect(Name.new('türko', "o özgür").name).to eq("Türko O'Özgür")
        expect(Name.new('türko', "l‘özgür").name).to eq("Türko L'Özgür")
      end

      it "backticks (0060), opening (2018) and closing (2019) single quotes, primes (2032) and high reversed 9 quotes (201B) should be equivalent" do
        expect(@una.match("Una", "O`Boyle")).to be_truthy
        expect(@una.match("Una", "O’Boyle")).to be_truthy
        expect(@una.match("Una", "O‘Boyle")).to be_truthy
        expect(@una.match("Una", "O′Boyle")).to be_truthy
        expect(@una.match("Una", "O‛Boyle")).to be_truthy
        expect(@una.match("Una", "O‚Boyle")).to be_falsey
      end
    end

    context "last beginning with Mc or Mac" do
      it "should be handled correctly" do
        expect(Name.new('shane', "mccabe").name).to eq("Shane McCabe")
        expect(Name.new('shawn', "macdonagh").name).to eq("Shawn Macdonagh")
        expect(Name.new('Colin', "MacNab").name).to eq("Colin MacNab")
        expect(Name.new('colin', "macnab").name).to eq("Colin Macnab")
        expect(Name.new('bartlomiej', "macieja").name).to eq("Bartlomiej Macieja")
        expect(Name.new('türko', "mcözgür").name).to eq("Türko McÖzgür")
        expect(Name.new('TÜRKO', "MACÖZGÜR").name).to eq("Türko Macözgür")
        expect(Name.new('Türko', "MacÖzgür").name).to eq("Türko MacÖzgür")
      end
    end

    context "first name initials" do
      it "should be handled correctly" do
        expect(Name.new('m j l', 'Orr').first).to eq('M. J. L.')
        expect(Name.new('Ö. é m', 'Panno').first).to eq("Ö. É. M.")
      end
    end

    context "doubled barrelled names or initials" do
      it "should be handled correctly" do
        expect(Name.new('anna-marie', 'den-otter').name).to eq('Anna-Marie Den-Otter')
        expect(Name.new('j-k', 'rowling').name).to eq('J.-K. Rowling')
        expect(Name.new("mark j. - l", 'ORR').name).to eq('Mark J.-L. Orr')
        expect(Name.new('JOHANNA', "lowry-o'REILLY").name).to eq("Johanna Lowry-O'Reilly")
        expect(Name.new('hannah', "lowry - o reilly").name).to eq("Hannah Lowry-O'Reilly")
        expect(Name.new('hannah', "lowry - o reilly").name).to eq("Hannah Lowry-O'Reilly")
        expect(Name.new('ètienne', "gèrard - mcözgür").name).to eq("Ètienne Gèrard-McÖzgür")
      end
    end

    context "names with II, III or IV" do
      it "should be handled correctly" do
        expect(Name.new('Jerry iIi', 'Jones').name).to eq('Jerry III Jones')
        expect(Name.new('henry i', 'FORD II').name).to eq('Henry I. Ford II')
        expect(Name.new('Paul IV', 'Pope').name).to eq('Paul IV Pope')
      end
    end

    context "accented characters and capitalisation" do
      it "should downcase upper case accented characters where appropriate" do
        name = Name.new('GEARÓIDÍN', 'UÍ LAIGHLÉIS')
        expect(name.first).to eq('Gearóidín')
        expect(name.last).to eq('Uí Laighléis')
      end

      it "should upcase upper case accented characters where appropriate" do
        name = Name.new('èric özgür')
        expect(name.first).to eq('Èric')
        expect(name.last).to eq('Özgür')
      end
    end

    context "extraneous white space" do
      it "should be handled correctly" do
        expect(Name.new(' mark j   l  ', "  \t\r\n   orr   \n").name).to eq('Mark J. L. Orr')
      end
    end

    context "extraneous full stops" do
      it "should be handled correctly" do
        expect(Name.new('. mark j..l', 'orr.').name).to eq('Mark J. L. Orr')
      end
    end

    context "construction from a single string" do
      it "should be possible in simple cases" do
        expect(Name.new('ORR, mark j l').rname).to eq('Orr, Mark J. L.')
        expect(Name.new('MARK J L ORR').rname).to eq('Orr, Mark J. L.')
        expect(Name.new("j-k O'Reilly").rname).to eq("O'Reilly, J.-K.")
        expect(Name.new("j-k O Reilly").rname).to eq("O'Reilly, J.-K.")
        expect(Name.new('ètienne o o özgür').name).to eq("Ètienne O. O'Özgür")
      end
    end

    context "construction from an instance" do
      it "should be possible" do
        expect(Name.new(Name.new('ORR, mark j l')).name).to eq('Mark J. L. Orr')
      end
    end

    context "the original input" do
      it "should be the original text unaltered except for white space" do
        expect(Name.new(' Mark   j l   ', ' ORR  ').original).to eq('ORR, Mark j l')
        expect(Name.new(' Mark  J.  L.  Orr ').original).to eq('Mark J. L. Orr')
        expect(Name.new('Józef', 'Żabiński').original).to eq('Żabiński, Józef')
        expect(Name.new('Ui  Laigleis,Gearoidin').original).to eq('Ui Laigleis,Gearoidin')
      end
    end

    context "encoding" do
      before(:each) do
        @first = 'Gearóidín'
        @last  = 'Uí Laighléis'
      end

      it "should handle UTF-8" do
        name = Name.new(@first, @last)
        expect(name.first).to eq(@first)
        expect(name.last).to eq(@last)
        expect(name.first.encoding.name).to eq("UTF-8")
        expect(name.last.encoding.name).to eq("UTF-8")
      end

      it "should handle ISO-8859-1" do
        name = Name.new(@first.encode("ISO-8859-1"), @last.encode("ISO-8859-1"))
        expect(name.first).to eq(@first)
        expect(name.last).to eq(@last)
        expect(name.first.encoding.name).to eq("UTF-8")
        expect(name.last.encoding.name).to eq("UTF-8")
      end

      it "should handle Windows-1252" do
        name = Name.new(@first.encode("Windows-1252"), @last.encode("Windows-1252"))
        expect(name.first).to eq(@first)
        expect(name.last).to eq(@last)
        expect(name.first.encoding.name).to eq("UTF-8")
        expect(name.last.encoding.name).to eq("UTF-8")
      end

      it "should handle ASCII-8BIT" do
        name = Name.new(@first.dup.force_encoding('ASCII-8BIT'), @last.dup.force_encoding('ASCII-8BIT'))
        expect(name.first).to eq(@first)
        expect(name.last).to eq(@last)
        expect(name.first.encoding.name).to eq("UTF-8")
        expect(name.last.encoding.name).to eq("UTF-8")
      end

      it "should handle US-ASCII" do
        @first = 'Gearoidin'
        @last  = 'Ui Laighleis'
        name = Name.new(@first.encode("US-ASCII"), @last.encode("US-ASCII"))
        expect(name.first).to eq(@first)
        expect(name.last).to eq(@last)
        expect(name.first.encoding.name).to eq("UTF-8")
        expect(name.last.encoding.name).to eq("UTF-8")
      end
    end

    context "transliteration" do
      before(:all) do
        @opt = { :chars => "US-ASCII" }
      end

      it "should be a no-op for names that are already ASCII" do
        name = Name.new('Mark J. L.', 'Orr')
        expect(name.first(@opt)).to eq('Mark J. L.')
        expect(name.last(@opt)).to eq('Orr')
        expect(name.name(@opt)).to eq('Mark J. L. Orr')
        expect(name.rname(@opt)).to eq('Orr, Mark J. L.')
        expect(name.to_s(@opt)).to eq('Orr, Mark J. L.')
      end

      it "should remove the accents from accented characters" do
        name = Name.new('Gearóidín', 'Uí Laighléis')
        expect(name.first(@opt)).to eq('Gearoidin')
        expect(name.last(@opt)).to eq('Ui Laighleis')
        expect(name.name(@opt)).to eq('Gearoidin Ui Laighleis')
        expect(name.rname(@opt)).to eq('Ui Laighleis, Gearoidin')
        expect(name.to_s(@opt)).to eq('Ui Laighleis, Gearoidin')
        name = Name.new('èric PRIÉ')
        expect(name.first(@opt)).to eq('Eric')
        expect(name.last(@opt)).to eq('Prie')
      end
    end

    context "constuction corner cases" do
      it "should be handled correctly" do
        expect(Name.new('Orr').name).to eq('Orr')
        expect(Name.new('Orr').rname).to eq('Orr')
        expect(Name.new('Uí Laighléis').rname).to eq('Laighléis, Uí')
        expect(Name.new('').name).to eq('')
        expect(Name.new('').rname).to eq('')
        expect(Name.new.name).to eq('')
        expect(Name.new.rname).to eq('')
      end
    end

    context "inputs to matching" do
      before(:all) do
        @mark = Name.new('Mark', 'Orr')
        @kram = Name.new('Mark', 'Orr')
      end

      it "should be flexible" do
        expect(@mark.match('Mark', 'Orr')).to be_truthy
        expect(@mark.match('Mark Orr')).to be_truthy
        expect(@mark.match('Orr, Mark')).to be_truthy
        expect(@mark.match(@kram)).to be_truthy
      end
    end

    context "first name matches" do
      it "should match when first names are the same" do
        expect(Name.new('Mark', 'Orr').match('Mark', 'Orr')).to be_truthy
      end

      it "should be flexible with regards to hyphens in double barrelled names" do
        expect(Name.new('J.-K.', 'Rowling').match('J. K.', 'Rowling')).to be_truthy
        expect(Name.new('Joanne-K.', 'Rowling').match('Joanne K.', 'Rowling')).to be_truthy
        expect(Name.new('Èric-K.', 'Cantona').match('Èric K.', 'Cantona')).to be_truthy
      end

      it "should match initials" do
        expect(Name.new('M. J. L.', 'Orr').match('Mark John Legard', 'Orr')).to be_truthy
        expect(Name.new('M.', 'Orr').match('Mark', 'Orr')).to be_truthy
        expect(Name.new('M. J. L.', 'Orr').match('Mark', 'Orr')).to be_truthy
        expect(Name.new('M.', 'Orr').match('M. J.', 'Orr')).to be_truthy
        expect(Name.new('M. J. L.', 'Orr').match('M. G.', 'Orr')).to be_falsey
        expect(Name.new('È', 'Cantona').match('Èric K.', 'Cantona')).to be_truthy
        expect(Name.new('E. K.', 'Cantona').match('Èric K.', 'Cantona')).to be_falsey
      end

      it "should not match on full names not in first position or without an exact match" do
        expect(Name.new('J. M.', 'Orr').match('John', 'Orr')).to be_truthy
        expect(Name.new('M. J.', 'Orr').match('John', 'Orr')).to be_falsey
        expect(Name.new('M. John', 'Orr').match('John', 'Orr')).to be_truthy
      end

      it "should handle common nicknames" do
        expect(Name.new('William', 'Orr').match('Bill', 'Orr')).to be_truthy
        expect(Name.new('David', 'Orr').match('Dave', 'Orr')).to be_truthy
        expect(Name.new('Mick', 'Orr').match('Mike', 'Orr')).to be_truthy
      end

      it "should handle ambiguous nicknames" do
        expect(Name.new('Gerry', 'Orr').match('Gerald', 'Orr')).to be_truthy
        expect(Name.new('Gerry', 'Orr').match('Gerard', 'Orr')).to be_truthy
        expect(Name.new('Gerard', 'Orr').match('Gerald', 'Orr')).to be_falsey
      end

      it "should handle some common misspellings" do
        expect(Name.new('Steven', 'Brady').match('Stephen', 'Brady')).to be_truthy
        expect(Name.new('Philip', 'Short').match('Phillip', 'Short')).to be_truthy
      end

      it "should have some conditional matches" do
        expect(Name.new('Sean', 'Bradley').match('John', 'Bradley')).to be_truthy
      end

      it "should not mix up nick names" do
        expect(Name.new('David', 'Orr').match('Bill', 'Orr')).to be_falsey
      end
    end

    context "last name matches" do
      it "should be flexible with regards to hyphens in double barrelled names" do
        expect(Name.new('Johanna', "Lowry-O'Reilly").match('Johanna', "Lowry O'Reilly")).to be_truthy
      end

      it "should be case insensitive in matches involving Macsomething and MacSomething" do
        expect(Name.new('Alan', 'MacDonagh').match('Alan', 'Macdonagh')).to be_truthy
      end

      it "should cater for the common mispelling of names beginning with Mc or Mac" do
        expect(Name.new('Alan', 'McDonagh').match('Alan', 'MacDonagh')).to be_truthy
        expect(Name.new('Darko', 'Polimac').match('Darko', 'Polimc')).to be_falsey
      end

      it "should have some conditional matches" do
        expect(Name.new('Debbie', 'Quinn').match('Debbie', 'Benjamin')).to be_truthy
        expect(Name.new('Mairead', "O'Siochru").match('Mairead', 'King')).to be_truthy
      end
    end

    context "matches involving accented characters" do
      it "should work for identical names" do
        expect(Name.new('Gearóidín', 'Uí Laighléis').match('Gearóidín', 'Uí Laighléis')).to be_truthy
        expect(Name.new('Gearóidín', 'Uí Laighléis').match('Gearoidin', 'Ui Laighleis')).to be_falsey
      end

      it "should work for first name initials" do
        expect(Name.new('Èric-K.', 'Cantona').match('È. K.', 'Cantona')).to be_truthy
        expect(Name.new('Èric-K.', 'Cantona').match('E. K.', 'Cantona')).to be_falsey
      end

      it "the matching of accented characters can be relaxed" do
        expect(Name.new('Gearóidín', 'Uí Laighléis').match('Gearoidin', 'Ui Laíghleis', :chars => "US-ASCII")).to be_truthy
        expect(Name.new('Èric-K.', 'Cantona').match('E. K.', 'Cantona', :chars => "US-ASCII")).to be_truthy
      end
    end

    context "configuring new first name alternatives" do
      before(:all) do
        load_alt_test(true, :first)
      end

      after(:all) do
        Name.reset_alternatives
      end

      it "should match some spelling errors" do
        expect(Name.new('Steven', 'Brady').match('Stephen', 'Brady')).to be_truthy
        expect(Name.new('Philip', 'Short').match('Phillip', 'Short')).to be_truthy
        expect(Name.new('Lyubomir', 'Orr').match('Lubomir', 'Orr')).to be_truthy
      end

      it "should handle conditional matches" do
        expect(Name.new('Sean', 'Collins').match('John', 'Collins')).to be_falsey
        expect(Name.new('Sean', 'Bradley').match('John', 'Bradley')).to be_truthy
      end
    end

    context "configuring new last name alternatives" do
      before(:all) do
        load_alt_test(true, :last)
      end

      after(:all) do
        Name.reset_alternatives
      end

      it "should match some spelling errors" do
        expect(Name.new('William', 'Ffrench').match('William', 'French')).to be_truthy
      end

      it "should handle conditional matches" do
        expect(Name.new('Mark', 'Quinn').match('Mark', 'Benjamin')).to be_falsey
        expect(Name.new('Debbie', 'Quinn').match('Debbie', 'Benjamin')).to be_truthy
        expect(Name.new('Oisin', "O'Siochru").match('Oisin', 'King')).to be_falsey
        expect(Name.new('Mairead', "O'Siochru").match('Mairead', 'King')).to be_truthy
      end

      it "should allow some awesome matches" do
        expect(Name.new('debbie quinn').match('Deborah', 'Benjamin')).to be_truthy
        expect(Name.new('french, william').match('Bill', 'Ffrench')).to be_truthy
        expect(Name.new('Oissine', 'Murphy').match('Oissine', 'Murchadha')).to be_truthy
      end
    end

    context "configuring new first and new last name alternatives" do
      before(:all) do
        load_alt_test(true, :first, :last)
      end

      after(:all) do
        Name.reset_alternatives
      end

      it "should allow some awesome matches" do
        expect(Name.new('french, steven').match('Stephen', 'Ffrench')).to be_truthy
        expect(Name.new('Patrick', 'Murphy').match('Padraic', 'Murchadha')).to be_truthy
      end
    end

    context "reverting to the default configuration" do
      before(:all) do
        load_alt_test(true, :first, :last)
      end

      after(:all) do
        Name.reset_alternatives
      end

      it "should not match after reverting" do
        expect(Name.new('avril, demeter').match('Ceres', 'Avril')).to be_truthy
        Name.load_alternatives(:first)
        expect(Name.new('avril, demeter').match('Ceres', 'Avril')).to be_falsey
        expect(Name.new('Patrick', 'Ares').match('Patrick', 'Mars')).to be_truthy
        Name.load_alternatives(:last)
        expect(Name.new('Patrick', 'Ares').match('Patrick', 'Mars')).to be_falsey
      end
    end

    context "name alternatives with default configuration" do
      it "should show common nicknames" do
        expect(Name.new('William', 'Ffrench').alternatives(:first)).to match_array(%w{Bill Willy Willie Will})
        expect(Name.new('Bill', 'Ffrench').alternatives(:first)).to match_array(%w{William Willy Will Willie})
        expect(Name.new('Steven', 'Ffrench').alternatives(:first)).to match_array(%w{Steve Stephen})
        expect(Name.new('Stephen', 'Ffrench').alternatives(:first)).to match_array(%w{Stef Stefan Stefen Stephan Steve Steven})
        expect(Name.new('Michael Stephen', 'Ffrench').alternatives(:first)).to match_array(%w{Micheal Mick Mickie Micky Mike Mikey Stef Stefan Stefen Stephan Steve Steven})
        expect(Name.new('Stephen M.', 'Ffrench').alternatives(:first)).to match_array(%w{Stef Stefan Stefen Stephan Steve Steven})
        expect(Name.new('Sean', 'Bradley').alternatives(:first)).to match_array(%w{John})
        expect(Name.new('S.', 'Ffrench').alternatives(:first)).to match_array([])
      end

      it "should have automatic last name alternatives for apostrophes to cater for FIDE's habits" do
        expect(Name.new('Mairead', "O'Siochru").alternatives(:last)).to match_array(%w{King O`Siochru})
        expect(Name.new('Erwin E.', "L`Ami").alternatives(:last)).to match_array(%w{L`Ami})
      end

      it "should not have some last name alternatives" do
        expect(Name.new('William', 'Ffrench').alternatives(:last)).to match_array(%w{French})
        expect(Name.new('Oissine', 'Murphy').alternatives(:last)).to match_array(%w{Murchadha})
        expect(Name.new('Debbie', 'Quinn').alternatives(:last)).to match_array(%w{Benjamin})
      end
    end

    context "name alternatives with more adventurous configuration" do
      before(:all) do
        load_alt_test(true, :first, :last)
      end

      after(:all) do
        Name.reset_alternatives
      end

      it "should show different nicknames" do
        expect(Name.new('Steven', 'Ffrench').alternatives(:first)).to match_array(%w{Stephen Steve})
        expect(Name.new('Stephen', 'Ffrench').alternatives(:first)).to match_array(%w{Steve Steven})
        expect(Name.new('Stephen Mike', 'Ffrench').alternatives(:first)).to match_array(%w{Michael Steve Steven})
        expect(Name.new('Sean', 'Bradley').alternatives(:first)).to match_array(%w{John})
        expect(Name.new('Sean', 'McDonagh').alternatives(:first)).to match_array([])
        expect(Name.new('John', 'Bradley').alternatives(:first)).to match_array(%w{Sean Johnny})
      end

      it "should have some last name alternatives" do
        expect(Name.new('William', 'Ffrench').alternatives(:last)).to match_array(%w{French})
        expect(Name.new('Mairead', "O'Siochru").alternatives(:last)).to match_array(%w{King O`Siochru})
        expect(Name.new('Oissine', 'Murphy').alternatives(:last)).to match_array(%w{Murchadha})
        expect(Name.new('Debbie', 'Quinn').alternatives(:last)).to match_array(%w{Benjamin})
        expect(Name.new('Mark', 'Quinn').alternatives(:last)).to match_array([])
        expect(Name.new('Debbie', 'Quinn-French').alternatives(:last)).to match_array(%w{Benjamin Ffrench})
      end
    end

    context "number of alternative compilations" do
      before(:all) do
        Name.reset_alternatives
      end

      after(:all) do
        Name.reset_alternatives
      end

      it "should be no more than necessary" do
        expect(alt_compilations(:first)).to eq(0)
        expect(alt_compilations(:last)).to eq(0)
        Name.new('William', 'Ffrench').match('Bill', 'French')
        expect(alt_compilations(:first)).to eq(1)
        expect(alt_compilations(:last)).to eq(1)
        Name.new('Debbie', 'Quinn').match('Deborah', 'Benjamin')
        expect(alt_compilations(:first)).to eq(1)
        expect(alt_compilations(:last)).to eq(1)
        load_alt_test(false, :first)
        expect(alt_compilations(:first)).to eq(2)
        expect(alt_compilations(:last)).to eq(1)
        load_alt_test(false, :last)
        expect(alt_compilations(:first)).to eq(2)
        expect(alt_compilations(:last)).to eq(2)
      end
    end

    context "immutability" do
      before(:each) do
        @mark = ICU::Name.new('Màrk', 'Orr')
      end

      it "there are no setters" do
        expect { @mark.first = "Malcolm" }.to raise_error(/undefined/)
        expect { @mark.last = "Dickie" }.to raise_error(/undefined/)
        expect { @mark.original = "mark orr" }.to raise_error(/undefined/)
      end

      it "should prevent accidentally access to the instance variables" do
        @mark.first.downcase!
        expect(@mark.first).to eq("Màrk")
        @mark.last.downcase!
        expect(@mark.last).to eq("Orr")
        @mark.original.downcase!
        expect(@mark.original).to eq("Orr, Màrk")
      end

      it "should prevent accidentally access to the instance variables when transliterating" do
        @mark.first(:chars => "US-ASCII").downcase!
        expect(@mark.first).to eq("Màrk")
        @mark.last(:chars => "US-ASCII").downcase!
        expect(@mark.last).to eq("Orr")
        @mark.original(:chars => "US-ASCII").downcase!
        expect(@mark.original).to eq("Orr, Màrk")
      end
    end
  end
end
