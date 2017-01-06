require_relative 'util.rb'
require 'celluloid/current'
WORKER_POOL_SIZE = 50

class CelluloidWorker
  include Celluloid

  def self.distribute(collection, method_name)
    worker_pool = pool(size: WORKER_POOL_SIZE)
    collection.map do |item|
      worker_pool.future.send(method_name, item)
    end.map(&:value)
  end

  def fetch_set_data(set_name)
    set_page = get Gatherer.url(for_set: set_name)
    set_img = set_page.css('img[src^="../../Handlers/Image.ashx?type=symbol&set="]').first
    set_code = set_img.attr(:src)[/set=(\w+)/, 1].downcase
    { 'name' => SET_NAME_OVERRIDES[set_name] || set_name,
      'code' => SET_CODE_OVERRIDES[set_code] || set_code }
  end

  def fetch_card_data(multiverse_id)
    return CARD_JSON_OVERRIDES[multiverse_id] if multiverse_id.in?(CARD_JSON_OVERRIDES)
    Gatherer.card_for(multiverse_id).as_json
  rescue => e
    puts "FAILED ON #{multiverse_id}: #{e}"
    puts e.backtrace.join("\n\t")
  end
end

class GathererSet
  attr_accessor :set
  def initialize(set); self.set = set; end

  # Dump each individual card for a given set.
  def run
    multiverse_ids = Gatherer.scrape_multiverse_ids(set)
    if multiverse_ids.empty?
      puts "No multiverse_ids found for #{gatherer_set_name}"; return false
    else
      return CelluloidWorker.distribute(multiverse_ids, :fetch_card_data).flatten.compact
    end
  end

  # Dump the metadata for all sets
  def self.run
    set_names = Gatherer.scrape_set_names
    set_json = CelluloidWorker.distribute(set_names, :fetch_set_data)
    self.merge(set_json).sort_by{|set| set['name']}
  end

  def self.merge(set_json)
    existing = Hash[read(SET_JSON_FILE_PATH).map{|s| [s['name'], s]}]
    set_json.each do |set|
      existing[set['name']] = (existing[set['name']] || {}).merge(set)
    end
    existing.values
  end
end
