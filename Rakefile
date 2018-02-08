require 'bundler'

# rake tasks to "build", "install", and "release" gem
Bundler::GemHelper.install_tasks

desc "Scrape set data from gatherer and write to sets.json"
task :sets do
  ruby "script/dump_sets.rb"
end

desc "Scrape card data from gatherer for sets provided via ARGV"
task :cards do
  ruby "script/dump_cards.rb #{ARGV[1..-1].join(' ')}"
end
