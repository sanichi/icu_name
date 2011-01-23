# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  describe Name do
    context "public methods" do
      before(:each) do
        @simple = Name.new('mark j l', 'orr')
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
        josef = ICU::Name.new('Józef', 'Żabiński')
        josef.name.should == "Józef Abiski"
        bu = ICU::Name.new('Bǔ Xiángzhì')
        bu.name.should == "B. Xiángzhì"
        eric = ICU::Name.new('éric', 'PRIÉ')
        eric.rname.should == "Prié, Éric"
        eric.rname.encoding.name.should == "UTF-8"
        eric = ICU::Name.new('éric'.encode("ISO-8859-1"), 'PRIÉ'.force_encoding("ASCII-8BIT"))
        eric.rname.should == "Prié, Éric"
        eric.rname.encoding.name.should == "UTF-8"
        eric.name(:ascii => true).should == "Eric Prie"
        eric_ascii = ICU::Name.new('éric', 'PRIÉ', :ascii => true)
        eric_ascii.name.should == "Eric Prie"
        eric.match('Éric', 'Prié').should be_true
        eric.match('Eric', 'Prie').should be_false
        eric.match('Eric', 'Prie', :ascii => true).should be_true
      end
    end

    context "names that are already canonical" do
      it "should not be altered" do
        Name.new('Mark J. L.', 'Orr').name.should == 'Mark J. L. Orr'
        Name.new('Anna-Marie J.-K.', 'Liviu-Dieter').name.should == 'Anna-Marie J.-K. Liviu-Dieter'
        Name.new('Èric Cantona').name.should == 'Èric Cantona'
      end
    end

    context "last names involving a quote" do
      it "should be handled correctly" do
        Name.new('una', "O'boyle").name.should == "Una O'Boyle"
        Name.new('jonathan', 'd`arcy').name.should == "Jonathan D'Arcy"
        Name.new('erwin e', "L'AMI").name.should == "Erwin E. L'Ami"
        Name.new('cormac', "o brien").name.should == "Cormac O'Brien"
        Name.new('türko', "o özgür").name.should == "Türko O'Özgür"
        Name.new('türko', "l`özgür").name.should == "Türko L'Özgür"
      end
    end

    context "last beginning with Mc or Mac" do
      it "should be handled correctly" do
        Name.new('shane', "mccabe").name.should == "Shane McCabe"
        Name.new('shawn', "macdonagh").name.should == "Shawn Macdonagh"
        Name.new('bartlomiej', "macieja").name.should == "Bartlomiej Macieja"
        Name.new('türko', "mcözgür").name.should == "Türko McÖzgür"
        Name.new('TÜRKO', "MACÖZGÜR").name.should == "Türko Macözgür"
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
        @opt = { :ascii => true }
      end

      it "should be a no-op for names that already ASCII" do
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

      it "should work for the constructor as well as accessors" do
        name = Name.new('Gearóidín', 'Uí Laighléis', @opt)
        name.first.should == 'Gearoidin'
        name.last.should == 'Ui Laighleis'
      end
    end

    context "constuction corner cases" do
      it "should be handled correctly" do
        Name.new('Orr').name.should == 'Orr'
        Name.new('Orr').rname.should == 'Orr'
        Name.new('Uí Laighléis').rname.should == 'Laighléis, Uí'
        Name.new('', 'Uí Laighléis', :ascii => true).last.should == 'Ui Laighleis'
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
        Name.new('Gearóidín', 'Uí Laighléis').match('Gearoidin', 'Ui Laíghleis', :ascii => true).should be_true
        Name.new('Èric-K.', 'Cantona').match('E. K.', 'Cantona', :ascii => true).should be_true
      end
    end
  end
end
