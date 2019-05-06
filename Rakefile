require 'bundler'

# rake tasks to "build", "install", and "release" gem
Bundler::GemHelper.install_tasks

desc "Scrape set data from Gatherer and write to data/sets.json"
task :sets do
  ruby "script/dump_sets.rb"
end

desc "Scrape card data from Gatherer for sets_codes listed in ARGV and write to data/sets/{set_code}.json"
task :cards do
  ruby "script/dump_cards.rb #{ARGV[1..-1].join(' ')}"
  ARGV[1..-1].map{|_| task(_.to_sym){}} # Rake tries to execute ARGV as tasks
end

desc "Scrape card comments from Gatherer for sets_codes listed in ARGV and write to data/comments/{set_code}.json"
task :comments do
  ruby "script/dump_comments.rb #{ARGV[1..-1].join(' ')}"
  ARGV[1..-1].map{|_| task(_.to_sym){}} # Rake tries to execute ARGV as tasks
end

desc "Update card data for sets not included in Gatherer."
task :non_gatherer_cards do
  ruby "script/update_non_gatherer_sets.rb"
end
