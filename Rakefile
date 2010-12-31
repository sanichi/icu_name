require 'rubygems'
require 'bundler'
require 'rake/rdoctask'
require 'rspec/core/rake_task'
require File.expand_path(File.dirname(__FILE__) + '/lib/icu_name/version')

version = ICU::Name::VERSION

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ['--colour --format nested']
end

Rake::RDocTask.new(:rdoc) do |t|
  t.title    = "ICU Name #{version}"
  t.rdoc_dir = 'rdoc'
  t.options  = ["--charset=utf-8"]
  t.rdoc_files.include('lib/**/*.rb', 'README.rdoc', 'LICENCE')
end
