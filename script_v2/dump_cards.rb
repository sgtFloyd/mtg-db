require 'celluloid/current'

# Require all files in util/ and scrapers/
Dir.glob(File.expand_path(File.join('..', 'util', '*.rb'), __FILE__), &method(:require))
Dir.glob(File.expand_path(File.join('..', 'scrapers', '*.rb'), __FILE__), &method(:require))

ALL_SETS = read(SET_JSON_FILE_PATH)
SETS_TO_DUMP = ARGV.any? ? ALL_SETS.select{|s| s['code'].in? ARGV} : ALL_SETS
WORKER_POOL_SIZE = 50

class CelluloidWorker
  include Celluloid

  def fetch_data(multiverse_id, set)
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

SETS_TO_DUMP.each do |set|
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
  else
    worker_pool = CelluloidWorker.pool(size: WORKER_POOL_SIZE)
    card_json = multiverse_ids.map do |multiverse_id|
      worker_pool.future.fetch_data(multiverse_id, set)
    end.map(&:value).flatten.compact

    # Output is sorted the same as search results
    write File.join(CARD_JSON_FILE_PATH, "#{set['code']}.json"), card_json
  end
end
