require_relative './script_util.rb'

ALL_SETS = read SET_JSON_FILE_PATH
SETS_TO_VALIDATE = ARGV.any? ? ALL_SETS.select{|s| s['code'].in? ARGV} : ALL_SETS
OLD_CARD_JSON = read File.expand_path('../../data/cards.json', __FILE__)

SETS_TO_VALIDATE.each do |set|
  old_json = OLD_CARD_JSON.select{|card| card['set_name'] == set['name']}
  new_json = read File.join(CARD_JSON_FILE_PATH, "#{set['code']}.json")

  puts "Count mismatch. Old: #{old_json.count} New: #{new_json.count}" if old_json.count != new_json.count

  print "Enter to continue..."; STDIN.gets
end
