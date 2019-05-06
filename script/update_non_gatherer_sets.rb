# Updates the JSON for sets not included in Gatherer using card attributes from
# other printings. Intended to be ran after a `rake cards` update.

NON_GATHERER_SETS = ['ath', 'dkm']

NON_GATHERER_SETS.each do |set_code|
  set_json_path = File.expand_path("../../data/sets/#{set_code}.json", __FILE__)
  File.open(set_json_path, 'r') do |set_json_file|
    set_json = JSON.parse(set_json_file.read)
    require 'pry'; binding.pry
  end
end
