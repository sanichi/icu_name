# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  describe Util do
    context "#is_utf8" do
      it "recognises US-ASCII as a special case of UTF-8" do
        expect(Util.is_utf8("Resume".encode("US-ASCII"))).to be_true
      end

      it "recognises UTF-8" do
        expect(Util.is_utf8("Résumé")).to be_true
        expect(Util.is_utf8("δog")).to be_true
      end

      it "should recognize other encodings as not being UTF-8" do
        expect(Util.is_utf8("Résumé".encode("ISO-8859-1"))).to be_false
        expect(Util.is_utf8("€50".encode("Windows-1252"))).to be_false
        expect(Util.is_utf8("ひらがな".encode("Shift_JIS"))).to be_false
        expect(Util.is_utf8("\xa3")).to be_false
      end
    end

    context "#to_utf8" do
      it "converts to UTF-8" do
        expect(Util.to_utf8("Resume")).to eq "Resume"
        expect(Util.to_utf8("Resume".force_encoding("US-ASCII")).encoding.name).to eq "UTF-8"
        expect(Util.to_utf8("Résumé".encode("ISO-8859-1"))).to eq "Résumé"
        expect(Util.to_utf8("Résumé".encode("Windows-1252"))).to eq "Résumé"
        expect(Util.to_utf8("€50".encode("Windows-1252"))).to eq "€50"
        expect(Util.to_utf8("\xa350".force_encoding("ASCII-8BIT"))).to eq "£50"
        expect(Util.to_utf8("\xa350")).to eq "£50"
        expect(Util.to_utf8("ひらがな".encode("Shift_JIS"))).to eq "ひらがな"
      end
    end
  end
end
