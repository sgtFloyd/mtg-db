# Updates the JSON for sets not included in Gatherer using card attributes from
# other printings. Intended to be ran after a `rake cards` update.
require './script/util/io.rb'

NON_GATHERER_SETS_WITH_SOURCES = {
  'ath' => [
    "lea", "leb", "2ed", "arn", "atq", "3ed", "leg", "drk", "fem", "4ed", "ice",
    "chr", "hml", "all", "mir", "vis", "5ed", "por", "wth", "tmp", "sth", "exo",
    "po2", "usg"
  ],
  'dkm' => [
    "lea", "leb", "2ed", "arn", "atq", "3ed", "leg", "drk", "fem", "4ed", "ice",
    "chr", "hml", "all", "mir", "vis", "5ed", "por", "wth", "tmp", "sth", "exo",
    "po2", "usg", "ulg", "6ed", "uds", "ptk", "s99", "mmq", "brb", "nem", "pcy",
    "s00", "inv", "btd", "pls", "7ed", "apc", "ody"
  ]
}

# Seed $set_json_cache as a cache of each source set's json.
$set_json_cache = {}
NON_GATHERER_SETS_WITH_SOURCES.values.flatten.uniq.each do |source_set_code|
  source_json_path = File.expand_path("../../data/sets/#{source_set_code}.json", __FILE__)
  $set_json_cache[source_set_code] = read(source_json_path)
end

NON_GATHERER_SETS_WITH_SOURCES.each do |set_code, source_set_codes|
  set_json_path = File.expand_path("../../data/sets/#{set_code}.json", __FILE__)
  non_gatherer_set_json = read(set_json_path)
  new_set_json = []

  # Search through sets printed before this non-gatherer set to find a prior
  # printing of each card. Take oracle text, types, rulings, etc from Gatherer card.
  non_gatherer_set_json.each do |card_json|
    card_candidates = []
    source_set_codes.each do |source_set_code|
      source_json = $set_json_cache[source_set_code]
      card_candidates += source_json.select{|card| card['name'] == card_json['name']}
    end

    candidate = card_candidates.first
    new_set_json << card_json.merge({
      'types' => candidate['types'],
      'supertypes' => candidate['supertypes'],
      'subtypes' => candidate['subtypes'],
      'mana_cost' => candidate['mana_cost'],
      'converted_mana_cost' => candidate['converted_mana_cost'],
      'oracle_text' => candidate['oracle_text'],
      'power' => candidate['power'],
      'toughness' => candidate['toughness'],
      'rulings' => candidate['rulings']
    })
  end
  write(set_json_path, new_set_json)
end
