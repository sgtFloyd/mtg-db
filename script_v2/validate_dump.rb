require_relative './script_util.rb'

ALL_SETS = read SET_JSON_FILE_PATH
SETS_TO_VALIDATE = ARGV.any? ? ALL_SETS.select{|s| s['code'].in? ARGV} : ALL_SETS
OLD_CARD_JSON = read File.expand_path('../../data/cards.json', __FILE__)

def record_flavor_text(multiverse_id, flavor_text)
  overrides = read(FLAVOR_TEXT_FILE_PATH, parser: YAML, silent: true)
  overrides[multiverse_id] = flavor_text
  File.open(FLAVOR_TEXT_FILE_PATH, 'w'){|f| f.write overrides.to_yaml}
end

def flavor_text_override_match?(card_attrs)
  overrides = read(FLAVOR_TEXT_FILE_PATH, parser: YAML, silent: true)
  overrides[card_attrs['multiverse_id']] == card_attrs['flavor_text']
end

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
        new_text = new_card[key].map{|l| l.gsub(/({C})+/){|_| "{#{_.scan('{C}').count}}"}}

        # Ignore mismatch when only reminder text is different.
        (old_card[key].map{|line| line.gsub(/\([^(]+\)/,'').strip} !=
          new_text.map{|line| line.gsub(/\([^(]+\)/,'').strip}) &&
        # Ignore mismatch if newly-introduced Menace keyword is present.
        new_text.join.exclude?('Menace')

      # Known issue: gatherer is missing punctuation on many cards' flavor_text.
      when 'flavor_text'
        if old_card[key] != new_card[key]
          next false if flavor_text_override_match?(new_card) # Override already processed
          puts "Flavor text mismatch on #{set['code']}##{old_card['collector_num']} (#{old_card['multiverse_id']}):"
          puts "  Old text (1): #{old_card[key]}"
          puts "  New text (2): #{new_card[key]}"
          response = STDIN.gets.strip
          if response.in?(['1', '2'])
            selected_text = [old_card[key], new_card[key]][response.to_i - 1]
            record_flavor_text(old_card['multiverse_id'], selected_text)
          end
        end
      else
        old_card[key] != new_card[key]
      end
    end
    if mismatches.any?
      puts "#{set['code']}##{old_card['collector_num']}: Mismatch: #{mismatches.join(', ')}"
      # print "Old:"; pp old_card; print "New:"; pp new_card; STDIN.gets
    end
  end

  new_json.each do |new_card|
    old_card = old_json.find{|old_card| old_card['collector_num'] == new_card['collector_num']}
    puts "#{set['code']}##{new_card['collector_num']}: Unexpected." if old_card.blank?
  end
end
