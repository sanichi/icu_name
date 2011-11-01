# -*- encoding: utf-8 -*-
require File.expand_path("../lib/icu_name/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "icu_name"
  s.version     = ICU::Name::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mark Orr"]
  s.email       = "mark.j.l.orr@googlemail.com"
  s.homepage    = "http://rubygems.org/gems/icu_name"
  s.summary     = "Canonicalises and matches person names"
  s.description = "Canonicalises and matches person names with Latin1 characters and first and last names"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "icu_name"

  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "i18n", ">= 0.5.0"

  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
  s.add_development_dependency("rspec")
  s.add_development_dependency("guard-rspec")
  s.add_development_dependency("rdoc")
  
  if RUBY_PLATFORM =~ /darwin/i
    s.add_development_dependency("rb-fsevent")
    s.add_development_dependency("growl")
  end

  s.files            = Dir.glob("lib/**/*.rb") + Dir.glob("spec/**/*.rb") + Dir.glob("config/*.yaml") + %w(LICENCE README.rdoc)
  s.extra_rdoc_files = %w(LICENCE README.rdoc)
  s.require_path     = 'lib'
end
