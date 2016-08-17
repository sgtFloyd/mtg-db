require_relative './script_util.rb'

ALL_SETS = read SET_JSON_FILE_PATH
SETS_TO_VALIDATE = ARGV.any? ? ALL_SETS.select{|s| s['code'].in? ARGV} : ALL_SETS
OLD_CARD_JSON = read File.expand_path('../../data/cards.json', __FILE__)

SETS_TO_VALIDATE.each do |set|
  old_json = OLD_CARD_JSON.select{|card| card['set_name'] == set['name']}
  new_json = read File.join(CARD_JSON_FILE_PATH, "#{set['code']}.json")

  old_json.each do |old_card|
    new_card = new_json.find{|new_card| new_card['collector_num'] == old_card['collector_num']}
    (puts "#{set['code']}##{old_card['collector_num']}: MISSING."; next) if new_card.blank?

    mismatches = old_card.keys.select do |key|
      case key
      when 'oracle_text'
        # Replace instances of ({C})+ in new text with backwards-compatible {1}, {2}
        new_text = new_card[key].map{|l| l.gsub(/({C})+/){|m| "{#{m.scan('{C}').count}}"}}

        # Ignore mismatch when only reminder text is different.
        (old_card[key].join.gsub(/\([^(]+\)/,'').strip !=
          new_text.join.gsub(/\([^(]+\)/,'').strip) &&
        # Ignore mismatch if newly-introduced Menace keyword is present.
        new_text.join.include?('Menace')

      # Known issue: gatherer is missing punctuation on many cards' flavor_text.
      when 'flavor_text' then next
      else
        old_card[key] != new_card[key]
      end
    end
    if mismatches.any?
      puts "#{set['code']}##{old_card['collector_num']}: Mismatch: #{mismatches.join(', ')}"
      print "Old:"; pp old_card; print "New:"; pp new_card; STDIN.gets
    end
  end

  new_json.each do |new_card|
    old_card = old_json.find{|old_card| old_card['collector_num'] == new_card['collector_num']}
    puts "#{set['code']}##{new_card['collector_num']}: Unexpected." if old_card.blank?
  end
end
