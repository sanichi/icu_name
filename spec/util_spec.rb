# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  describe Util do
    context "#is_utf8" do
      it "should recognise US-ASCII as a special case of UTF-8" do
        Util.is_utf8("Resume".encode("US-ASCII")).should be_true
      end

      it "should recognise UTF-8" do
        Util.is_utf8("Résumé").should be_true
        Util.is_utf8("δog").should be_true
      end

      it "should recognize other encodings as not being UTF-8" do
        Util.is_utf8("Résumé".encode("ISO-8859-1")).should be_false
        Util.is_utf8("€50".encode("Windows-1252")).should be_false
        Util.is_utf8("ひらがな".encode("Shift_JIS")).should be_false
        Util.is_utf8("\xa3").should be_false
      end
    end

    context "#to_utf8" do
      it "should convert to UTF-8" do
        Util.to_utf8("Resume").should == "Resume"
        Util.to_utf8("Resume".force_encoding("US-ASCII")).encoding.name.should == "UTF-8"
        Util.to_utf8("Résumé".encode("ISO-8859-1")).should == "Résumé"
        Util.to_utf8("Résumé".encode("Windows-1252")).should == "Résumé"
        Util.to_utf8("€50".encode("Windows-1252")).should == "€50"
        Util.to_utf8("\xa350".force_encoding("ASCII-8BIT")).should == "£50"
        Util.to_utf8("\xa350").should == "£50"
        Util.to_utf8("ひらがな".encode("Shift_JIS")).should == "ひらがな"
      end
    end
  end
end