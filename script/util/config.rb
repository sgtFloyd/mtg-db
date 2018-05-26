require 'yaml'

SET_JSON_FILE_PATH =    File.expand_path('../../../data/sets.json', __FILE__)
CARD_JSON_FILE_PATH =   File.expand_path('../../../data/sets', __FILE__)
FLAVOR_TEXT_FILE_PATH = File.expand_path('../../data/flavor_text_overrides.yml', __FILE__)

%w[
  excluded_sets
  excluded_multiverse_ids
  set_code_overrides
  set_name_overrides
  card_json_overrides
  collector_num_overrides
  flavor_text_overrides
  illustrator_overrides
  subtitle_display_overrides
  split_card_names
  mana_cost_symbols
].each do |config|
  path = File.expand_path "../../data/#{config}.yml", __FILE__
  self.class.const_set config.upcase, YAML.load_file(path)
end

# Hardcoded list of supertypes, allows us to differentiate between types and
# supertypes when parsing a card's type line.
CARD_SUPERTYPES = ['Basic', 'Legendary', 'World', 'Snow']

# Some tokens are missing the "Token" type. Check for these exact names instead.
EXCLUDED_TOKEN_NAMES = ['Goblin', 'Soldier', 'Kraken', 'Spirit', 'Demon',
  'Elemental', 'Thrull', 'Elf Warrior', 'Beast', 'Elephant', 'Elemental Shaman',
  'Minion', 'Saproling', 'Hornet']

# Used to override the oracle text of each Basic Land type.
BASIC_LAND_SYMBOLS = {
  'Plains'   => '{W}', 'Island' => '{U}', 'Swamp'  => '{B}',
  'Mountain' => '{R}', 'Forest' => '{G}', 'Wastes' => '{C}',
  'Snow-Covered Plains' => '{W}', 'Snow-Covered Island' => '{U}',
  'Snow-Covered Swamp' => '{B}', 'Snow-Covered Mountain' => '{R}',
  'Snow-Covered Forest' => '{G}'
}
