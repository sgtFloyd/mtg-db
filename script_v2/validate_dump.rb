require_relative './script_util.rb'

ALL_SETS = read SET_JSON_FILE_PATH
SETS_TO_VALIDATE = ARGV.any? ? ALL_SETS.select{|s| s['code'].in? ARGV} : ALL_SETS
OLD_CARD_JSON = read File.expand_path('../../data/cards.json', __FILE__)
EXCLUDED_VALIDATIONS = YAML.load_file(File.expand_path '../data/excluded_validations.yml', __FILE__)

SETS_TO_VALIDATE.each do |set|
  old_json = OLD_CARD_JSON.select{|card| card['set_name'] == set['name']}
  new_json = read File.join(CARD_JSON_FILE_PATH, "#{set['code']}.json")

  old_json.each do |old_card|
    next if EXCLUDED_VALIDATIONS[set['code']].include?(old_card['collector_num'])
    new_card = new_json.find{|new_card| new_card['collector_num'] == old_card['collector_num']}
    (puts "#{set['code']}##{old_card['collector_num']}: Missing."; next) if new_card.blank?

    mismatches = old_card.keys.select{|key| old_card[key] != new_card[key]}
    if mismatches.any?
      puts "#{set['code']}##{old_card['collector_num']}: Mismatch: #{mismatches.join(', ')}"
    end
  end

  new_json.each do |new_card|
    old_card = old_json.find{|old_card| old_card['collector_num'] == new_card['collector_num']}
    puts "#{set['code']}##{new_card['collector_num']}: Unexpected." if old_card.blank?
  end
end
