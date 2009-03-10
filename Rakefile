require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'

desc 'Default: run specs.'
task :default => :spec

desc 'Runs the drails ruby specs.'
Spec::Rake::SpecTask.new(:runspec) do |t|
  t.libs << 'lib'
  t.spec_files = FileList['spec/**/*_spec.rb']
end

desc 'Test the iotear ruby specs'
task :spec  => ['runspec'] do
end

desc 'Generate documentation.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'iotear'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end