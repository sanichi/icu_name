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

  s.add_runtime_dependency "activesupport", ">= 3.0.6"
  s.add_runtime_dependency "i18n", ">= 0.5.0"

  s.add_development_dependency "bundler", ">= 1.0.7"
  s.add_development_dependency "rspec", "~> 2.5"
  s.add_development_dependency "ZenTest", "~> 4.4.2"
  s.add_development_dependency "autotest-growl", "~> 0.2.9"
  s.add_development_dependency "autotest-fsevent", "~> 0.2.4"

  s.files            = Dir.glob("lib/**/*.rb") + Dir.glob("spec/**/*.rb") + Dir.glob("config/*.yaml") + %w(LICENCE README.rdoc)
  s.extra_rdoc_files = %w(LICENCE README.rdoc)
  s.require_path     = 'lib'
end
