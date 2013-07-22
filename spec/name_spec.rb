# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  describe Name do
    def load_alt_test(*types)
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
        @simple.first.should == 'Mark J. L.'
      end

      it "#last returns the last name(s)" do
        @simple.last.should == 'Orr'
      end

      it "#name returns the full name with first name(s) first" do
        @simple.name.should == 'Mark J. L. Orr'
      end

      it "#rname returns the full name with last name(s) first" do
        @simple.rname.should == 'Orr, Mark J. L.'
      end

      it "#to_s is the same as rname" do
        @simple.to_s.should == 'Orr, Mark J. L.'
      end

      it "#original returns the original data" do
        @simple.original.should == 'ORR, mark j l'
      end

      it "#match returns true if and only if two names match" do
        @simple.match('mark j l orr').should be_true
        @simple.match('malcolm g l orr').should be_false
      end
    end

    context "rdoc expample" do
      before(:each) do
        @robert = Name.new(' robert  j ', ' FISCHER ')
        @bobby = Name.new(' bobby fischer ')
      end

      it "should get Robert" do
        @robert.name.should == 'Robert J. Fischer'
      end

      it "should get Bobby" do
        @bobby.last.should == 'Fischer'
        @bobby.first.should == 'Bobby'
      end

      it "should match Robert and Bobby" do
        @robert.match(@bobby).should be_true
        @robert.match('R. J.', 'Fischer').should be_true
        @bobby.match('R. J.', 'Fischer').should be_false
      end

      it "should canconicalise last names" do
        Name.new('John', 'O Reilly').last.should == "O'Reilly"
        Name.new('dave', 'mcmanus').last.should == "McManus"
        Name.new('pete', 'MACMANUS').last.should == "Macmanus"
      end

      it "characters and encoding" do
        ICU::Name.new('éric', 'PRIÉ').name.should == "Éric Prié"
        ICU::Name.new('BARTŁOMIEJ', 'śliwa').name.should == "Bartomiej Liwa"
        ICU::Name.new('Սմբատ', 'Լպուտյան').name.should == ""
        eric = Name.new('éric'.encode("ISO-8859-1"), 'PRIÉ'.force_encoding("ASCII-8BIT"))
        eric.rname.should == "Prié, Éric"
        eric.rname.encoding.name.should == "UTF-8"
        eric.original.should == "PRIÉ, éric"
        eric.original.encoding.name.should == "UTF-8"
        eric.rname(:chars => "US-ASCII").should == "Prie, Eric"
        eric.original(:chars => "US-ASCII").should == "PRIE, eric"
        eric.match('Éric', 'Prié').should be_true
        eric.match('Eric', 'Prie').should be_false
        eric.match('Eric', 'Prie', :chars => "US-ASCII").should be_true
      end
    end

    context "names that are already canonical" do
      it "should not be altered" do
        Name.new('Mark J. L.', 'Orr').name.should == 'Mark J. L. Orr'
        Name.new('Anna-Marie J.-K.', 'Liviu-Dieter').name.should == 'Anna-Marie J.-K. Liviu-Dieter'
        Name.new('Èric Cantona').name.should == 'Èric Cantona'
      end
    end

    context "last names involving single quote-like characters" do
      before(:each) do
        @una = Name.new('Una', "O'Boyle")
      end

      it "should use apostrophe (0027) as the canonical choice" do
        Name.new('una', "O'boyle").name.should == "Una O'Boyle"
        Name.new('Una', "o’boyle").name.should == "Una O'Boyle"
        Name.new('jonathan', 'd`arcy').name.should == "Jonathan D'Arcy"
        Name.new('erwin e', "L′AMI").name.should == "Erwin E. L'Ami"
        Name.new('cormac', "o brien").name.should == "Cormac O'Brien"
        Name.new('türko', "o özgür").name.should == "Türko O'Özgür"
        Name.new('türko', "l‘özgür").name.should == "Türko L'Özgür"
      end

      it "backticks (0060), opening (2018) and closing (2019) single quotes, primes (2032) and high reversed 9 quotes (201B) should be equivalent" do
        @una.match("Una", "O`Boyle").should be_true
        @una.match("Una", "O’Boyle").should be_true
        @una.match("Una", "O‘Boyle").should be_true
        @una.match("Una", "O′Boyle").should be_true
        @una.match("Una", "O‛Boyle").should be_true
        @una.match("Una", "O‚Boyle").should be_false
      end
    end

    context "last beginning with Mc or Mac" do
      it "should be handled correctly" do
        Name.new('shane', "mccabe").name.should == "Shane McCabe"
        Name.new('shawn', "macdonagh").name.should == "Shawn Macdonagh"
        Name.new('Colin', "MacNab").name.should == "Colin MacNab"
        Name.new('colin', "macnab").name.should == "Colin Macnab"
        Name.new('bartlomiej', "macieja").name.should == "Bartlomiej Macieja"
        Name.new('türko', "mcözgür").name.should == "Türko McÖzgür"
        Name.new('TÜRKO', "MACÖZGÜR").name.should == "Türko Macözgür"
        Name.new('Türko', "MacÖzgür").name.should == "Türko MacÖzgür"
      end
    end

    context "first name initials" do
      it "should be handled correctly" do
        Name.new('m j l', 'Orr').first.should == 'M. J. L.'
        Name.new('Ö. é m', 'Panno').first.should == "Ö. É. M."
      end
    end

    context "doubled barrelled names or initials" do
      it "should be handled correctly" do
        Name.new('anna-marie', 'den-otter').name.should == 'Anna-Marie Den-Otter'
        Name.new('j-k', 'rowling').name.should == 'J.-K. Rowling'
        Name.new("mark j. - l", 'ORR').name.should == 'Mark J.-L. Orr'
        Name.new('JOHANNA', "lowry-o'REILLY").name.should == "Johanna Lowry-O'Reilly"
        Name.new('hannah', "lowry - o reilly").name.should == "Hannah Lowry-O'Reilly"
        Name.new('hannah', "lowry - o reilly").name.should == "Hannah Lowry-O'Reilly"
        Name.new('ètienne', "gèrard - mcözgür").name.should == "Ètienne Gèrard-McÖzgür"
      end
    end

    context "accented characters and capitalisation" do
      it "should downcase upper case accented characters where appropriate" do
        name = Name.new('GEARÓIDÍN', 'UÍ LAIGHLÉIS')
        name.first.should == 'Gearóidín'
        name.last.should == 'Uí Laighléis'
      end

      it "should upcase upper case accented characters where appropriate" do
        name = Name.new('èric özgür')
        name.first.should == 'Èric'
        name.last.should == 'Özgür'
      end
    end

    context "extraneous white space" do
      it "should be handled correctly" do
        Name.new(' mark j   l  ', "  \t\r\n   orr   \n").name.should == 'Mark J. L. Orr'
      end
    end

    context "extraneous full stops" do
      it "should be handled correctly" do
        Name.new('. mark j..l', 'orr.').name.should == 'Mark J. L. Orr'
      end
    end

    context "construction from a single string" do
      it "should be possible in simple cases" do
        Name.new('ORR, mark j l').rname.should == 'Orr, Mark J. L.'
        Name.new('MARK J L ORR').rname.should == 'Orr, Mark J. L.'
        Name.new("j-k O'Reilly").rname.should == "O'Reilly, J.-K."
        Name.new("j-k O Reilly").rname.should == "O'Reilly, J.-K."
        Name.new('ètienne o o özgür').name.should == "Ètienne O. O'Özgür"
      end
    end

    context "construction from an instance" do
      it "should be possible" do
        Name.new(Name.new('ORR, mark j l')).name.should == 'Mark J. L. Orr'
      end
    end

    context "the original input" do
      it "should be the original text unaltered except for white space" do
        Name.new(' Mark   j l   ', ' ORR  ').original.should == 'ORR, Mark j l'
        Name.new(' Mark  J.  L.  Orr ').original.should == 'Mark J. L. Orr'
        Name.new('Józef', 'Żabiński').original.should == 'Żabiński, Józef'
        Name.new('Ui  Laigleis,Gearoidin').original.should == 'Ui Laigleis,Gearoidin'
      end
    end

    context "encoding" do
      before(:each) do
        @first = 'Gearóidín'
        @last  = 'Uí Laighléis'
      end

      it "should handle UTF-8" do
        name = Name.new(@first, @last)
        name.first.should == @first
        name.last.should == @last
        name.first.encoding.name.should == "UTF-8"
        name.last.encoding.name.should == "UTF-8"
      end

      it "should handle ISO-8859-1" do
        name = Name.new(@first.encode("ISO-8859-1"), @last.encode("ISO-8859-1"))
        name.first.should == @first
        name.last.should == @last
        name.first.encoding.name.should == "UTF-8"
        name.last.encoding.name.should == "UTF-8"
      end

      it "should handle Windows-1252" do
        name = Name.new(@first.encode("Windows-1252"), @last.encode("Windows-1252"))
        name.first.should == @first
        name.last.should == @last
        name.first.encoding.name.should == "UTF-8"
        name.last.encoding.name.should == "UTF-8"
      end

      it "should handle ASCII-8BIT" do
        name = Name.new(@first.dup.force_encoding('ASCII-8BIT'), @last.dup.force_encoding('ASCII-8BIT'))
        name.first.should == @first
        name.last.should == @last
        name.first.encoding.name.should == "UTF-8"
        name.last.encoding.name.should == "UTF-8"
      end

      it "should handle US-ASCII" do
        @first = 'Gearoidin'
        @last  = 'Ui Laighleis'
        name = Name.new(@first.encode("US-ASCII"), @last.encode("US-ASCII"))
        name.first.should == @first
        name.last.should == @last
        name.first.encoding.name.should == "UTF-8"
        name.last.encoding.name.should == "UTF-8"
      end
    end

    context "transliteration" do
      before(:all) do
        @opt = { :chars => "US-ASCII" }
      end

      it "should be a no-op for names that are already ASCII" do
        name = Name.new('Mark J. L.', 'Orr')
        name.first(@opt).should == 'Mark J. L.'
        name.last(@opt).should == 'Orr'
        name.name(@opt).should == 'Mark J. L. Orr'
        name.rname(@opt).should == 'Orr, Mark J. L.'
        name.to_s(@opt).should == 'Orr, Mark J. L.'
      end

      it "should remove the accents from accented characters" do
        name = Name.new('Gearóidín', 'Uí Laighléis')
        name.first(@opt).should == 'Gearoidin'
        name.last(@opt).should == 'Ui Laighleis'
        name.name(@opt).should == 'Gearoidin Ui Laighleis'
        name.rname(@opt).should == 'Ui Laighleis, Gearoidin'
        name.to_s(@opt).should == 'Ui Laighleis, Gearoidin'
        name = Name.new('èric PRIÉ')
        name.first(@opt).should == 'Eric'
        name.last(@opt).should == 'Prie'
      end
    end

    context "constuction corner cases" do
      it "should be handled correctly" do
        Name.new('Orr').name.should == 'Orr'
        Name.new('Orr').rname.should == 'Orr'
        Name.new('Uí Laighléis').rname.should == 'Laighléis, Uí'
        Name.new('').name.should == ''
        Name.new('').rname.should == ''
        Name.new.name.should == ''
        Name.new.rname.should == ''
      end
    end

    context "inputs to matching" do
      before(:all) do
        @mark = Name.new('Mark', 'Orr')
        @kram = Name.new('Mark', 'Orr')
      end

      it "should be flexible" do
        @mark.match('Mark', 'Orr').should be_true
        @mark.match('Mark Orr').should be_true
        @mark.match('Orr, Mark').should be_true
        @mark.match(@kram).should be_true
      end
    end

    context "first name matches" do
      it "should match when first names are the same" do
        Name.new('Mark', 'Orr').match('Mark', 'Orr').should be_true
      end

      it "should be flexible with regards to hyphens in double barrelled names" do
        Name.new('J.-K.', 'Rowling').match('J. K.', 'Rowling').should be_true
        Name.new('Joanne-K.', 'Rowling').match('Joanne K.', 'Rowling').should be_true
        Name.new('Èric-K.', 'Cantona').match('Èric K.', 'Cantona').should be_true
      end

      it "should match initials" do
        Name.new('M. J. L.', 'Orr').match('Mark John Legard', 'Orr').should be_true
        Name.new('M.', 'Orr').match('Mark', 'Orr').should be_true
        Name.new('M. J. L.', 'Orr').match('Mark', 'Orr').should be_true
        Name.new('M.', 'Orr').match('M. J.', 'Orr').should be_true
        Name.new('M. J. L.', 'Orr').match('M. G.', 'Orr').should be_false
        Name.new('È', 'Cantona').match('Èric K.', 'Cantona').should be_true
        Name.new('E. K.', 'Cantona').match('Èric K.', 'Cantona').should be_false
      end

      it "should not match on full names not in first position or without an exact match" do
        Name.new('J. M.', 'Orr').match('John', 'Orr').should be_true
        Name.new('M. J.', 'Orr').match('John', 'Orr').should be_false
        Name.new('M. John', 'Orr').match('John', 'Orr').should be_true
      end

      it "should handle common nicknames" do
        Name.new('William', 'Orr').match('Bill', 'Orr').should be_true
        Name.new('David', 'Orr').match('Dave', 'Orr').should be_true
        Name.new('Mick', 'Orr').match('Mike', 'Orr').should be_true
      end

      it "should handle ambiguous nicknames" do
        Name.new('Gerry', 'Orr').match('Gerald', 'Orr').should be_true
        Name.new('Gerry', 'Orr').match('Gerard', 'Orr').should be_true
        Name.new('Gerard', 'Orr').match('Gerald', 'Orr').should be_false
      end

      it "should by default be cautious about misspellings" do
        Name.new('Steven', 'Brady').match('Stephen', 'Brady').should be_false
        Name.new('Philip', 'Short').match('Phillip', 'Short').should be_false
      end

      it "should by default have no conditional matches" do
        Name.new('Sean', 'Bradley').match('John', 'Bradley').should be_false
      end

      it "should not mix up nick names" do
        Name.new('David', 'Orr').match('Bill', 'Orr').should be_false
      end
    end

    context "last name matches" do
      it "should be flexible with regards to hyphens in double barrelled names" do
        Name.new('Johanna', "Lowry-O'Reilly").match('Johanna', "Lowry O'Reilly").should be_true
      end

      it "should be case insensitive in matches involving Macsomething and MacSomething" do
        Name.new('Alan', 'MacDonagh').match('Alan', 'Macdonagh').should be_true
      end

      it "should cater for the common mispelling of names beginning with Mc or Mac" do
        Name.new('Alan', 'McDonagh').match('Alan', 'MacDonagh').should be_true
        Name.new('Darko', 'Polimac').match('Darko', 'Polimc').should be_false
      end

      it "should by defaut have no conditional matches" do
        Name.new('Debbie', 'Quinn').match('Debbie', 'Benjamin').should be_false
        Name.new('Mairead', "O'Siochru").match('Mairead', 'King').should be_false
      end
    end

    context "matches involving accented characters" do
      it "should work for identical names" do
        Name.new('Gearóidín', 'Uí Laighléis').match('Gearóidín', 'Uí Laighléis').should be_true
        Name.new('Gearóidín', 'Uí Laighléis').match('Gearoidin', 'Ui Laighleis').should be_false
      end

      it "should work for first name initials" do
        Name.new('Èric-K.', 'Cantona').match('È. K.', 'Cantona').should be_true
        Name.new('Èric-K.', 'Cantona').match('E. K.', 'Cantona').should be_false
      end

      it "the matching of accented characters can be relaxed" do
        Name.new('Gearóidín', 'Uí Laighléis').match('Gearoidin', 'Ui Laíghleis', :chars => "US-ASCII").should be_true
        Name.new('Èric-K.', 'Cantona').match('E. K.', 'Cantona', :chars => "US-ASCII").should be_true
      end
    end

    context "configuring new first name alternatives" do
      before(:all) do
        load_alt_test(:first)
      end

      it "should match some spelling errors" do
        Name.new('Steven', 'Brady').match('Stephen', 'Brady').should be_true
        Name.new('Philip', 'Short').match('Phillip', 'Short').should be_true
        Name.new('Lyubomir', 'Orr').match('Lubomir', 'Orr').should be_true
      end

      it "should handle conditional matches" do
        Name.new('Sean', 'Collins').match('John', 'Collins').should be_false
        Name.new('Sean', 'Bradley').match('John', 'Bradley').should be_true
      end
    end

    context "configuring new last name alternatives" do
      before(:all) do
        load_alt_test(:last)
      end

      it "should match some spelling errors" do
        Name.new('William', 'Ffrench').match('William', 'French').should be_true
      end

      it "should handle conditional matches" do
        Name.new('Mark', 'Quinn').match('Mark', 'Benjamin').should be_false
        Name.new('Debbie', 'Quinn').match('Debbie', 'Benjamin').should be_true
        Name.new('Oisin', "O'Siochru").match('Oisin', 'King').should be_false
        Name.new('Mairead', "O'Siochru").match('Mairead', 'King').should be_true
      end

      it "should allow some awesome matches" do
        Name.new('debbie quinn').match('Deborah', 'Benjamin').should be_true
        Name.new('french, william').match('Bill', 'Ffrench').should be_true
        Name.new('Oissine', 'Murphy').match('Oissine', 'Murchadha').should be_true
      end
    end

    context "configuring new first and new last name alternatives" do
      before(:all) do
        load_alt_test(:first, :last)
      end

      it "should allow some awesome matches" do
        Name.new('french, steven').match('Stephen', 'Ffrench').should be_true
        Name.new('Patrick', 'Murphy').match('Padraic', 'Murchadha').should be_true
      end
    end

    context "reverting to the default configuration" do
      before(:all) do
        load_alt_test(:first, :last)
      end

      it "should not match so boldly after reverting" do
        Name.new('french, steven').match('Stephen', 'Ffrench').should be_true
        Name.load_alternatives(:first)
        Name.new('Patrick', 'Murphy').match('Padraic', 'Murchadha').should be_false
        Name.new('Patrick', 'Murphy').match('Patrick', 'Murchadha').should be_true
        Name.load_alternatives(:last)
        Name.new('Patrick', 'Murphy').match('Patrick', 'Murchadha').should be_false
      end
    end

    context "name alternatives with default configuration" do
      it "should show common nicknames" do
        Name.new('William', 'Ffrench').alternatives(:first).should =~ %w{Bill Willy Willie Will}
        Name.new('Bill', 'Ffrench').alternatives(:first).should =~ %w{William Willy Will Willie}
        Name.new('Steven', 'Ffrench').alternatives(:first).should =~ %w{Steve}
        Name.new('Stephen', 'Ffrench').alternatives(:first).should =~ %w{Steve}
        Name.new('Michael Stephen', 'Ffrench').alternatives(:first).should =~ %w{Steve Mike Mick Mikey}
        Name.new('Stephen M.', 'Ffrench').alternatives(:first).should =~ %w{Steve}
        Name.new('S.', 'Ffrench').alternatives(:first).should =~ []
        Name.new('Sean', 'Bradley').alternatives(:first).should =~ []
      end

      it "should have automatic last name alternatives for apostrophes to cater for FIDE's habits" do
        Name.new('Mairead', "O'Siochru").alternatives(:last).should =~ ["O`Siochru"]
        Name.new('Erwin E.', "L`Ami").alternatives(:last).should =~ ["L`Ami"]
      end

      it "should not have any last name alternatives" do
        Name.new('William', 'Ffrench').alternatives(:last).should =~ []
        Name.new('Oissine', 'Murphy').alternatives(:last).should =~ []
        Name.new('Debbie', 'Quinn').alternatives(:last).should =~ []
      end
    end

    context "name alternatives with more adventurous configuration" do
      before(:all) do
        load_alt_test(:first, :last)
      end

      it "should show additional nicknames" do
        Name.new('Steven', 'Ffrench').alternatives(:first).should =~ %w{Stephen Steve}
        Name.new('Stephen', 'Ffrench').alternatives(:first).should =~ %w{Stef Stefan Stefen Stephan Steve Steven}
        Name.new('Stephen Mike', 'Ffrench').alternatives(:first).should =~ %w{Michael Mick Mickie Micky Mikey Stef Stefan Stefen Stephan Steve Steven}
        Name.new('Sean', 'Bradley').alternatives(:first).should =~ %w{John}
        Name.new('Sean', 'McDonagh').alternatives(:first).should =~ []
        Name.new('John', 'Bradley').alternatives(:first).should =~ %w{Sean Johnny}
      end

      it "should have some last name alternatives" do
        Name.new('William', 'Ffrench').alternatives(:last).should =~ %w{French}
        Name.new('Mairead', "O'Siochru").alternatives(:last).should =~ %w{King O`Siochru}
        Name.new('Oissine', 'Murphy').alternatives(:last).should =~ %w{Murchadha}
        Name.new('Debbie', 'Quinn').alternatives(:last).should =~ %w{Benjamin}
        Name.new('Mark', 'Quinn').alternatives(:last).should =~ []
        Name.new('Debbie', 'Quinn-French').alternatives(:last).should =~ %w{Benjamin Ffrench}
      end
    end

    context "number of alternative compilations" do
      before(:all) do
        Name.reset_alternatives
      end

      it "should be no more than necessary" do
        alt_compilations(:first).should == 0
        alt_compilations(:last).should == 0
        Name.new('William', 'Ffrench').match('Bill', 'French')
        alt_compilations(:first).should == 1
        alt_compilations(:last).should == 1
        Name.new('Debbie', 'Quinn').match('Deborah', 'Benjamin')
        alt_compilations(:first).should == 1
        alt_compilations(:last).should == 1
        load_alt_test(:first)
        alt_compilations(:first).should == 2
        alt_compilations(:last).should == 1
        load_alt_test(:last)
        alt_compilations(:first).should == 2
        alt_compilations(:last).should == 2
        Name.new('William', 'Ffrench').match('Bill', 'French')
        Name.new('Debbie', 'Quinn').match('Deborah', 'Benjamin')
        Name.new('Mark', 'Orr').alternatives(:first)
        Name.new('Mark', 'Orr').alternatives(:last)
        alt_compilations(:first).should == 2
        alt_compilations(:last).should == 2
      end
    end

    context "immutability" do
      before(:each) do
        @mark = ICU::Name.new('Màrk', 'Orr')
      end

      it "there are no setters" do
        lambda { @mark.first = "Malcolm" }.should raise_error(/undefined/)
        lambda { @mark.last = "Dickie" }.should raise_error(/undefined/)
        lambda { @mark.original = "mark orr" }.should raise_error(/undefined/)
      end

      it "should prevent accidentally access to the instance variables" do
        @mark.first.downcase!
        @mark.first.should == "Màrk"
        @mark.last.downcase!
        @mark.last.should == "Orr"
        @mark.original.downcase!
        @mark.original.should == "Orr, Màrk"
      end

      it "should prevent accidentally access to the instance variables when transliterating" do
        @mark.first(:chars => "US-ASCII").downcase!
        @mark.first.should == "Màrk"
        @mark.last(:chars => "US-ASCII").downcase!
        @mark.last.should == "Orr"
        @mark.original(:chars => "US-ASCII").downcase!
        @mark.original.should == "Orr, Màrk"
      end
    end
  end
end
