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

  # Search through sets printed before this non-gatherer set to find a prior
  # printing of each card. Take oracle text, types, rulings, etc from Gatherer card.
  non_gatherer_set_json.map{|c| c['name']}.each do |card_name|
    candidates = []
    source_set_codes.each do |source_set_code|
      source_json = $set_json_cache[source_set_code]
      candidates += source_json.select{|card| card['name'] == card_name}
    end

    # If all candidates have the same rules text, just use it.
    candidates = candidates.uniq do |c|
      [c['oracle_text'], c['types'], c['supertypes'], c['subtypes'], c['rulings']]
    end
    require 'pry'; binding.pry
  end
end
