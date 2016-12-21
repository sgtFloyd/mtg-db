require_relative './script_util.rb'

ALL_SETS = read(SET_JSON_FILE_PATH)
SETS_TO_DUMP = ARGV.any? ? ALL_SETS.select{|s| s['code'].in? ARGV} : ALL_SETS
WORKER_POOL_SIZE = 25

class CardScraper
  extend Memoizer
  attr_accessor :multiverse_id, :page

  def initialize(multiverse_id, page)
    self.multiverse_id = multiverse_id
    self.page = page
  end

  memo def parse_name
    page.css('[id$="subtitleDisplay"]').text.strip
  end

  memo def parse_collector_num
    COLLECTOR_NUM_OVERRIDES[multiverse_id] || labeled_row(:number)
  end

  SUPERTYPES = %w[Basic Legendary World Snow]
  memo def parse_types
    types = labeled_row(:type).split("—").map(&:strip)[0].split(' ') - SUPERTYPES
    supertypes = labeled_row(:type).split("—").map(&:strip)[0].split(' ') & SUPERTYPES
    subtypes = labeled_row(:type).split("—").map(&:strip)[1].gsub("’", "'").split(' ') rescue []
    { types: types, supertypes: supertypes, subtypes: subtypes }
  end

  memo def parse_set_name
    set_name_str = labeled_row(:set)
    SET_NAME_OVERRIDES[set_name_str] || set_name_str
  end

  memo def parse_mana_cost
    container.css('[id$="manaRow"] .value img').map do |symbol|
      symbol_key = symbol.attr(:alt).strip
      MANA_COST_SYMBOLS[symbol_key] || symbol_key
    end.join
  end

  memo def parse_oracle_text
    # Override oracle text for basic lands.
    if parse_types[:supertypes].include?('Basic')
      return  ["({T}: Add #{BASIC_LAND_SYMBOL[parse_name]} to your mana pool.)"]
    end

    textboxes = container.css('[id$="textRow"] .cardtextbox')
    textboxes.map do |textbox|
      textbox.css(:img).each do |img|
        img_alt = img.attr(:alt).strip
        symbol = MANA_COST_SYMBOLS[img_alt] || img_alt
        symbol = "{#{symbol}}" unless symbol.match(/^{/)
        img.replace(symbol)
      end
      # Gatherer messes up {10} formatting, resulting in {1}0
      textbox.text.strip.gsub('{1}0', '{10}')
    end.select(&:present?)
  end

  memo def parse_flavor_text
    return FLAVOR_TEXT_OVERRIDES[multiverse_id] if FLAVOR_TEXT_OVERRIDES[multiverse_id]
    textboxes = container.css('[id$="flavorRow"] .flavortextbox')
    textboxes.map{|t| t.text.strip}.select(&:present?).join("\n").presence
  end

  memo def parse_pt
    if parse_types[:types].include?('Planeswalker')
      { loyalty: labeled_row(:pt) }
    elsif parse_types[:types].include?('Creature')
      { power:     labeled_row(:pt).split('/')[0].strip,
        toughness: labeled_row(:pt).split('/')[1].strip }
    else
      {}
    end
  end

  ILLUSTRATOR_REPLACEMENTS = {
    "Brian Snoddy" => "Brian Snõddy",
    "Parente & Brian Snoddy" => "Parente & Brian Snõddy",
    "ROn Spencer" => "Ron Spencer",
    "s/b Lie Tiu" => "Lie Tiu"
  }
  memo def parse_illustrator
    artist_str = labeled_row(:artist)
    ILLUSTRATOR_OVERRIDES[multiverse_id] ||
      ILLUSTRATOR_REPLACEMENTS[artist_str] || artist_str
  end

  RARITY_REPLACEMENTS = {'Basic Land' => 'Land'}
  memo def parse_rarity
    rarity_str = labeled_row(:rarity)
    RARITY_REPLACEMENTS[rarity_str] || rarity_str
  end

  def as_json(options={})
    return if parse_types[:types].include?('Token') ||
                parse_name.in?(EXCLUDED_TOKEN_NAMES)
    {
      'name'                => parse_name,
      'set_name'            => parse_set_name,
      'collector_num'       => parse_collector_num,
      'illustrator'         => parse_illustrator,
      'types'               => parse_types[:types],
      'supertypes'          => parse_types[:supertypes],
      'subtypes'            => parse_types[:subtypes],
      'rarity'              => parse_rarity,
      'mana_cost'           => parse_mana_cost.presence,
      'converted_mana_cost' => labeled_row(:cmc).to_i,
      'oracle_text'         => parse_oracle_text,
      'flavor_text'         => parse_flavor_text,
      'power'               => parse_pt[:power],
      'toughness'           => parse_pt[:toughness],
      'loyalty'             => parse_pt[:loyalty],
      'multiverse_id'       => multiverse_id,
      'other_part'          => nil,
      'color_indicator'     => labeled_row(:colorIndicator).presence,
    }
  end

private

  # Grab the .cardComponentContainer that corresponds with this card. Flip,
  # split, and transform cards can have multiple containers on the page and
  # may need to be handled differently
  memo def container
    page.css('.cardComponentContainer').find do |container|
      container.css('[id$="nameRow"] .value').text.strip ==
        page.css('[id$="subtitleDisplay"]').text.strip
    end
  end

  memo def labeled_row(label)
    container.css("[id$=\"#{label}Row\"] .value").text.strip
  end
end

class SplitCardScraper < CardScraper

  memo def parse_name
    SPLIT_CARD_NAMES[multiverse_id] || (raise "Unknown split card: #{multiverse_id}")
  end

  memo def parse_collector_num
    cnum = labeled_row(:number).gsub(/[^\d]/, '')
    first_name = parse_name.scan(/\(([^\/]+)/).flatten.first
    expected_name == first_name ? "#{cnum}a" : "#{cnum}b"
  end

  # Alter full name, replacing expected_name with other_name
  def parse_other_part
    both_names = parse_name.scan(/\(([^)]+)\)/).flatten.first
    other_name = both_names.gsub(expected_name, '').gsub(/\//, '')
    "#{other_name} (#{both_names})"
  end

  def as_json(options={})
    super.merge('other_part' => parse_other_part)
  end

private

  # Most sets assign the same multiverse_id to both halves of a split card,
  # "overloading" the id. Others assign a unique multiverse_id to each half.
  SETS_WITHOUT_OVERLOADED_MULTIVERSE_IDS = ['Apocalypse', 'Invastion']
  memo def overload_multiverse_id?
    !parse_set_name.in? SETS_WITHOUT_OVERLOADED_MULTIVERSE_IDS
  end

  # Remove split name from parse_name, "Fire (Fire/Ice)" => "Fire"
  memo def expected_name
    parse_name.gsub(/\s+\([^)]*\)/, '')
  end

  # Grab the .cardComponentContainer that corresponds with this card. Ensure
  # the name displayed in the container matches the name in SPLIT_CARD_NAMES.
  memo def container
    page.css('.cardComponentContainer').find do |container|
      container.css('[id$="nameRow"] .value').text.strip == expected_name
    end
  end
end

class CelluloidWorker
  include Celluloid

  def fetch_data(multiverse_id)
    page = get("http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=#{multiverse_id}")
    scraper = CardScraper.new(multiverse_id, page)
    # Split cards are displayed as "Fire // Ice"
    if scraper.parse_name.include?('//')
      scraper = SplitCardScraper.new(multiverse_id, page)
    end
    scraper.as_json
  end
end

SETS_TO_DUMP.each do |set|
  # Cookie contains setting to retrieve all results in a single page, instead of the default 100 results per page.
  gatherer_set_name = SET_NAME_OVERRIDES.invert[set['name']] || set['name']
  set_url = "http://gatherer.wizards.com/Pages/Search/Default.aspx?sort=cn+&output=compact&set=[%22#{gatherer_set_name}%22]"
  cookie = "CardDatabaseSettings=0=1&1=28&2=0&14=1&3=13&4=0&5=1&6=15&7=0&8=1&9=1&10=19&11=7&12=8&15=1&16=0&13=;"
  response = get(set_url, "Cookie" => cookie)

  multiverse_ids = response.css('.cardItem [id$="cardPrintings"] a').map do |link|
    link.attr(:href)[/multiverseid=(\d+)/, 1].to_i
  end.uniq

  worker_pool = CelluloidWorker.pool(size: WORKER_POOL_SIZE)
  card_json = multiverse_ids.map do |multiverse_id|
    worker_pool.future.fetch_data(multiverse_id)
  end.map(&:value).compact

  # Output is sorted the same as search results, by collector num.
  write File.join(CARD_JSON_FILE_PATH, "#{set['code']}.json"), card_json
end
