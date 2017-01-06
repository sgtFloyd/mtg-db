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
    set_page = get "http://gatherer.wizards.com/Pages/Search/Default.aspx?set=[%22#{set_name}%22]"
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
    gatherer_set_name = SET_NAME_OVERRIDES.invert[set['name']] || set['name']
    gatherer_set_name = 'Commander 2014' if gatherer_set_name == 'Commander 2014 Edition' # hardcoded so it works. lazy.

    # Cookie contains setting to retrieve all results in a single page, instead of the default 100 results per page.
    set_url = "http://gatherer.wizards.com/Pages/Search/Default.aspx?sort=cn+&output=compact&set=[%22#{gatherer_set_name}%22]"
    cookie = "CardDatabaseSettings=0=1&1=28&2=0&14=1&3=13&4=0&5=1&6=15&7=0&8=1&9=1&10=19&11=7&12=8&15=1&16=0&13=;"
    response = get(set_url, "Cookie" => cookie)

    multiverse_ids = response.css('.cardItem [id$="cardPrintings"] a').map do |link|
      link.attr(:href)[/multiverseid=(\d+)/, 1].to_i
    end.uniq - EXCLUDED_MULTIVERSE_IDS

    # s00#13 is missing from Gatherer. This will pull the data from CARD_JSON_OVERRIDES
    multiverse_ids << 's00#13' if set['code'] == 's00'

    if multiverse_ids.empty?
      puts "No multiverse_ids found for #{gatherer_set_name}"
      return false
    else
      card_json = CelluloidWorker.distribute(multiverse_ids, :fetch_card_data)
      return card_json.flatten.compact
    end
  end

  # Dump the metadata for all sets
  def self.run
    page = get "http://gatherer.wizards.com/Pages/Default.aspx"
    set_names = page.css('select[name$="setAddText"] option').map(&:text)
    set_names.reject!(&:empty?).reject!{|name| name.in?(EXCLUDED_SETS)}

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
