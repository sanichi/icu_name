# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  module Util
    describe String do
      context "#is_utf8" do
        it "recognises some encodings as a special case of UTF-8" do
          expect(String.is_utf8("Resume".encode("US-ASCII"))).to be_true
          expect(String.is_utf8("Resume".encode("ASCII-8BIT"))).to be_true
          expect(String.is_utf8("Resume".encode("BINARY"))).to be_true
        end

        it "recognises UTF-8" do
          expect(String.is_utf8("Résumé")).to be_true
          expect(String.is_utf8("δog")).to be_true
        end

        it "should recognize other encodings as not being UTF-8" do
          expect(String.is_utf8("Résumé".encode("ISO-8859-1"))).to be_false
          expect(String.is_utf8("€50".encode("Windows-1252"))).to be_false
          expect(String.is_utf8("ひらがな".encode("Shift_JIS"))).to be_false
          expect(String.is_utf8("\xa3")).to be_false
        end
      end

      context "#to_utf8" do
        it "converts to UTF-8" do
          expect(String.to_utf8("Resume")).to eq "Resume"
          expect(String.to_utf8("Resume".force_encoding("US-ASCII")).encoding.name).to eq "UTF-8"
          expect(String.to_utf8("Résumé".encode("ISO-8859-1"))).to eq "Résumé"
          expect(String.to_utf8("Résumé".encode("Windows-1252"))).to eq "Résumé"
          expect(String.to_utf8("€50".encode("Windows-1252"))).to eq "€50"
          expect(String.to_utf8("\xa350".force_encoding("ASCII-8BIT"))).to eq "£50"
          expect(String.to_utf8("\xa350")).to eq "£50"
          expect(String.to_utf8("ひらがな".encode("Shift_JIS"))).to eq "ひらがな"
        end
      end

      context "#downcase" do
        it "downcases characters in the Latin-1 range" do
          expect(String.downcase("Eric")).to eq "eric"
          expect(String.downcase("Éric")).to eq "éric"
          expect(String.downcase("ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÑÒÓÔÕÖØÙÚÛÜÝÞ")).to eq "àáâãäåæçèéêëìíîïñòóôõöøùúûüýþ"
        end
      end

      context "#upcase" do
        it "upcases characters in the Latin-1 range" do
          expect(String.upcase("Gearoidin")).to eq "GEAROIDIN"
          expect(String.upcase("Gearóidín")).to eq "GEARÓIDÍN"
          expect(String.upcase("àáâãäåæçèéêëìíîïñòóôõöøùúûüýþ")).to eq "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÑÒÓÔÕÖØÙÚÛÜÝÞ"
        end
      end

      context "#capitalize" do
        it "capitalizes strings that might contain accented characters" do
          expect(String.capitalize("gearoidin")).to eq "Gearoidin"
          expect(String.capitalize("GEAROIDIN")).to eq "Gearoidin"
          expect(String.capitalize("gEAróiDÍn")).to eq "Gearóidín"
          expect(String.capitalize("ériC")).to eq "Éric"
          expect(String.capitalize("ÉRIc")).to eq "Éric"
        end
      end
    end
    
    describe AlternativeNames do
      context "extends" do
        class Dummy
          extend AlternativeNames
        end
        
        it "#last_name_like" do
          expect(Dummy.last_name_like("Murphy", "Oissine")).to eq "last_name LIKE '%Murchadha%' OR last_name LIKE '%Murphy%'"
          expect(Dummy.last_name_like("O'Connor", "Jonathan")).to eq "last_name LIKE '%O''Connor%' OR last_name LIKE '%O`Connor%'"
          expect(Dummy.last_name_like("O'Connor", "\n")).to eq "last_name LIKE '%O''Connor%' OR last_name LIKE '%O`Connor%'"
          expect(Dummy.last_name_like("O'Connor")).to eq "last_name LIKE '%O''Connor%' OR last_name LIKE '%O`Connor%'"
          expect(Dummy.last_name_like("Orr", "Mark")).to eq "last_name LIKE '%Orr%'"
          expect(Dummy.last_name_like("", "Mark")).to eq "last_name LIKE '%%'"
        end

        it "#first_name_like" do
          expect(Dummy.first_name_like("sean", "bradley")).to eq "first_name LIKE '%John%' OR first_name LIKE '%sean%'"
          expect(Dummy.first_name_like("Jonathan", "O'Connor")).to eq "first_name LIKE '%Jon%' OR first_name LIKE '%Jonathan%'"
          expect(Dummy.first_name_like("Jonathan", " ")).to eq "first_name LIKE '%Jon%' OR first_name LIKE '%Jonathan%'"
          expect(Dummy.first_name_like("Jonathan")).to eq "first_name LIKE '%Jon%' OR first_name LIKE '%Jonathan%'"
          expect(Dummy.first_name_like("", "O'Connor")).to eq "first_name LIKE '%%'"
        end
      end
    end
  end
end
