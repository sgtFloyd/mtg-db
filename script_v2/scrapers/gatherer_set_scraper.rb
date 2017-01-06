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

  def fetch_card_data(multiverse_id, set)
    return CARD_JSON_OVERRIDES[multiverse_id] if multiverse_id.in?(CARD_JSON_OVERRIDES)
    page = get("http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=#{multiverse_id}")
    scraper = GathererCardScraper.new(multiverse_id, page)

    # Split cards are displayed as "Fire // Ice"
    if scraper.parse_name.include?('//')
      scraper = GathererSplitCardScraper.new(multiverse_id, page, set)

    # Both Flip and DoubleFaced cards will display two images on the pages
    elsif page.css('img[id$="cardImage"]').count > 1
      mana_costs = scraper.containers.map do |container|
        container.css('[id$="manaRow"] .value img').map do |symbol|
          GathererCardScraper.translate_mana_symbol(symbol)
        end.join
      end
      # Only one side of a DoubleFaced card will have a mana cost.
      # ... or zero, in the case of Westvale Abbey.
      if mana_costs.select(&:present?).count < 2
        scraper = GathererDoubleFacedCardScraper.new(multiverse_id, page)
      else
        scraper = GathererFlipCardScraper.new(multiverse_id, page)
      end
    end

    scraper.as_json
  rescue => e
    puts "FAILED ON #{multiverse_id}: #{e}"
  end
end

class GathererSetScraper
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
      worker_pool = CelluloidWorker.pool(size: WORKER_POOL_SIZE)
      card_json = multiverse_ids.map do |multiverse_id|
        worker_pool.future.fetch_card_data(multiverse_id, set)
      end.map(&:value).flatten.compact
      return card_json
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
