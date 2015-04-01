require 'bundler/gem_tasks'

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = Dir.glob('spec/**/*_spec.rb').sort
  t.verbose = true
end

# task(default: :test)
