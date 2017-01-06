Dir.glob(File.expand_path(File.join('..', 'util', '*.rb'), __FILE__), &method(:require))
require_relative './gatherer/set.rb'

ALL_SETS = read(SET_JSON_FILE_PATH)
SETS_TO_DUMP = ARGV.any? ? ALL_SETS.select{|s| s['code'].in? ARGV} : ALL_SETS

SETS_TO_DUMP.each do |set|
  card_json = GathererSet.new(set['name']).card_json
  if card_json.present?
    # Output is sorted the same as search results
    write File.join(CARD_JSON_FILE_PATH, "#{set['code']}.json"), card_json
  else
    puts "No multiverse_ids found for #{set['name']}"
  end
end
