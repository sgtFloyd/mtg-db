require_relative './script_util.rb'

ALL_SETS = read SET_JSON_FILE_PATH
VERBOSE_MODE = ARGV.delete('-v')
INTERACTIVE_MODE = ARGV.delete('-i')
SETS_TO_VALIDATE = ARGV.any? ? ALL_SETS.select{|s| s['code'].in? ARGV} : ALL_SETS
OLD_CARD_JSON = read File.expand_path('../../data/cards.json', __FILE__)

def record_flavor_text(multiverse_id, flavor_text, set: nil)
  # Insert override into flavor_text_overrides.yml
  overrides = read(FLAVOR_TEXT_FILE_PATH, parser: YAML, silent: true)
  overrides[multiverse_id] = flavor_text
  File.open(FLAVOR_TEXT_FILE_PATH, 'w'){|f| f.write overrides.to_yaml}

  # Update set json with new flavor text, if necessary
  set_json = read File.join(CARD_JSON_FILE_PATH, "#{set['code']}.json"), silent: true
  card_index = set_json.index{|card| card['multiverse_id'] == multiverse_id}
  if set_json[card_index]['flavor_text'] != flavor_text
    set_json[card_index]['flavor_text'] = flavor_text
    write File.join(CARD_JSON_FILE_PATH, "#{set['code']}.json"), set_json
  end
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
        new_text.join.exclude?('Menace') && new_text.join.exclude?('menace') &&
        # Ignore mismatch if newly-worded "additional creature" is present.
        new_text.join.exclude?('additional creature each combat')

      when 'flavor_text'
        # Ignore discrepancies where old flavor text is only missing line breaks
        mismatch = old_card[key].to_s != new_card[key].to_s.gsub("\n", "")
        next mismatch unless INTERACTIVE_MODE
        if mismatch
          mixed_text = old_card[key].to_s.sub("—", "\n—")
          contains_exclamation = old_card[key].to_s.include?('!')
          puts "Flavor text mismatch on #{set['code']}##{old_card['collector_num']} (#{old_card['multiverse_id']})#{" !!!!!" if contains_exclamation}:"
          puts "  Old   (1): #{old_card[key].to_s.gsub("\n", '\n')}"
          puts "  New   (2): #{new_card[key].to_s.gsub("\n", '\n')}"
          puts "  Mixed (3): #{mixed_text.gsub("\n", '\n')}"
          response = STDIN.gets.strip
          if response.in? ['1', '2', '3']
            selected_text = [old_card[key], new_card[key], mixed_text][response.to_i - 1]
            record_flavor_text(old_card['multiverse_id'], selected_text, set: set)
          end
        end
      when 'mana_cost'
        old_symbols = old_card[key].to_s.split('').sort
        new_symbols = new_card[key].to_s.split('').sort
        # If the mismatch is simply in the mana cost's order, trust the version
        # from Gatherer. The old data has been notoriously incorrect.
        next old_symbols != new_symbols
      when 'illustrator'
        if old_card[key] == 'Brian Snoddy' && new_card[key] == 'Brian Snõddy'
          next false
        else
          old_card[key] != new_card[key]
        end
      when 'set_name'
        expected_name = SET_NAME_OVERRIDES[old_card[key]] || old_card[key]
        expected_name != new_card[key]
      else
        old_card[key] != new_card[key]
      end
    end
    if mismatches.any?
      puts "#{set['code']}##{old_card['collector_num']}: Mismatch: #{mismatches.join(', ')}"
      (print "Old:"; pp old_card; print "New:"; pp new_card; STDIN.gets) if VERBOSE_MODE
    end
  end

  new_json.each do |new_card|
    old_card = old_json.find{|old_card| old_card['collector_num'] == new_card['collector_num']}
    if old_card.blank?
      puts "#{set['code']}##{new_card['collector_num']}: Unexpected."
      require 'pry'; binding.pry
    end
  end
end
