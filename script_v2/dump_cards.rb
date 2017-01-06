require_relative './script_util.rb'

ALL_SETS = read(SET_JSON_FILE_PATH)
SETS_TO_DUMP = ARGV.any? ? ALL_SETS.select{|s| s['code'].in? ARGV} : ALL_SETS
WORKER_POOL_SIZE = 50

class CardScraper
  extend Memoizer
  attr_accessor :multiverse_id, :page

  def initialize(multiverse_id, page)
    self.multiverse_id = multiverse_id
    self.page = page
  end

  SUBTITLE_DISPLAY_OVERRIDES = {
    # Fix missing Æ in subtitle
    1557 => 'Ærathi Berserker',
    417611 => 'Æther Tradewinds',
    # Fix inconsistent capitalization
    91 => 'Will-o\'-the-Wisp',
    386 => 'Will-o\'-the-Wisp',
    688 => 'Will-o\'-the-Wisp',
    1187 => 'Will-o\'-the-Wisp',
    2138 => 'Will-o\'-the-Wisp',
    1436 => 'Evil Eye of Orms-by-Gore',
    4596 => 'Altar of Dementia',
    4883 => 'Knight of Dawn',
    # Bizarre Gatherer bug, prepending 'XX' to some card names
    106628 => 'Valor',
    109672 => 'Call of the Herd',
    # Fix incorrect spacing around colon
    241 => 'Circle of Protection: Blue',
    242 => 'Circle of Protection: Green',
    243 => 'Circle of Protection: Red',
    244 => 'Circle of Protection: White',
  }
  memo def parse_name
    name_str = page.css('[id$="subtitleDisplay"]').text.strip
    SUBTITLE_DISPLAY_OVERRIDES[multiverse_id] || name_str
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
      self.class.translate_mana_symbol(symbol)
    end.join
  end
  def self.translate_mana_symbol(symbol)
    symbol_key = symbol.attr(:alt).strip
    MANA_COST_SYMBOLS[symbol_key] || symbol_key
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

  def parse_color_indicator
    color_indicator_str = labeled_row(:colorIndicator).presence
    color_indicator_str.split(', ').join(' ') if color_indicator_str
  end

  CARD_NAME_OVERRIDES = {
    91 => 'Will-O\'-The-Wisp',
    386 => 'Will-O\'-The-Wisp',
    688 => 'Will-O\'-The-Wisp',
    1187 => 'Will-O\'-The-Wisp',
    2138 => 'Will-O\'-The-Wisp',
  }
  def as_json(options={})
    return if parse_types[:types].include?('Token') ||
                parse_name.in?(EXCLUDED_TOKEN_NAMES)
    {
      'name'                => CARD_NAME_OVERRIDES[multiverse_id] || parse_name,
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
      'color_indicator'     => parse_color_indicator,
    }
  end

  # Grab the .cardComponentContainer that corresponds with this card. Flip,
  # split, and transform cards can have multiple containers on the page and
  # may need to be handled differently
  def container
    containers.find do |container|
      subtitleDisplay = SUBTITLE_DISPLAY_OVERRIDES[multiverse_id] ||
                          page.css('[id$="subtitleDisplay"]').text.strip
      container.css('[id$="nameRow"] .value').text.strip == subtitleDisplay
    end
  end

  def containers
    page.css('.cardComponentContainer')
  end

  memo def labeled_row(label)
    container.css("[id$=\"#{label}Row\"] .value").text.strip
  end
end

class SplitCardScraper < CardScraper
  attr_accessor :given_set, :container_index

  def initialize(multiverse_id, page, given_set, container_index=nil)
    super(multiverse_id, page)
    self.given_set = given_set
    self.container_index = container_index
  end

  memo def parse_name
    if overload_multiverse_id?
      # Coerce gatherer naming scheme "Fire // Ice" into ours "Fire (Fire/Ice)"
      # using container_index to determine which half we're dealing with
      gatherer_name = page.css('[id$="subtitleDisplay"]').text.strip
      names = gatherer_name.split(' // ')
      "#{labeled_row(:name)} (#{names.join('/')})"
    else
      SPLIT_CARD_NAMES[multiverse_id] || (raise "Unknown split card: #{multiverse_id}")
    end
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
    if overload_multiverse_id? && !self.container_index.present?
      containers.map.with_index do |_, i|
        SplitCardScraper.new(multiverse_id, page, given_set, i).as_json
      end
    else
      super.merge('other_part' => parse_other_part)
    end
  end

  # Most sets assign the same multiverse_id to both halves of a split card,
  # "overloading" the id. Others assign a unique multiverse_id to each half.
  SETS_WITHOUT_OVERLOADED_MULTIVERSE_IDS = ['Apocalypse', 'Invasion']
  memo def overload_multiverse_id?
    !self.given_set['name'].in? SETS_WITHOUT_OVERLOADED_MULTIVERSE_IDS
  end

  # Remove split name from parse_name, "Fire (Fire/Ice)" => "Fire"
  memo def expected_name
    parse_name.gsub(/\s+\([^)]*\)/, '')
  end

  # Grab the .cardComponentContainer that corresponds with this card. Ensure
  # the name displayed in the container matches the name in SPLIT_CARD_NAMES.
  memo def container
    return containers[self.container_index] if self.container_index.present?
    containers.find do |container|
      container.css('[id$="nameRow"] .value').text.strip == expected_name
    end
  end
end

class FlipCardScraper < CardScraper
  attr_accessor :container_index

  def initialize(multiverse_id, page, container_index=nil)
    super(multiverse_id, page)
    self.container_index = container_index
  end

  memo def parse_name
    labeled_row(:name)
  end

  memo def parse_other_part
    # Use xor to get the "other" container
    containers[1^self.container_index].css("[id$=\"nameRow\"] .value").text.strip
  end

  def as_json(options={})
    if !self.container_index.present?
      containers.map.with_index do |_, i|
        FlipCardScraper.new(multiverse_id, page, i).as_json
      end
    else
      super.merge('other_part' => parse_other_part)
    end
  end

  def container
    # We shouldn't be trying to access the container until we've selected a
    # side (via container_index), so don't worry about a fallback.
    containers[self.container_index]
  end
end

class DoubleFacedCardScraper < CardScraper
  memo def parse_other_part
    containers.each do |container|
      container_name = container.css("[id$=\"nameRow\"] .value").text.strip
      return container_name if container_name != parse_name
    end
  end

  memo def parse_flavor_text
    return FLAVOR_TEXT_OVERRIDES[multiverse_id] if FLAVOR_TEXT_OVERRIDES[multiverse_id]
    textboxes = container.css('[id$="flavorRow"] .cardtextbox')
    textboxes.map{|t| t.text.strip}.select(&:present?).join("\n").presence
  end

  def as_json(options={})
    super.merge('other_part' => parse_other_part)
  end

  memo def container
    containers.find do |container|
      container.css('[id$="nameRow"] .value').text.strip == parse_name
    end
  end
end

class CelluloidWorker
  include Celluloid

  def fetch_data(multiverse_id, set)
    return CARD_JSON_OVERRIDES[multiverse_id] if multiverse_id.in?(CARD_JSON_OVERRIDES)
    page = get("http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=#{multiverse_id}")
    scraper = CardScraper.new(multiverse_id, page)

    # Split cards are displayed as "Fire // Ice"
    if scraper.parse_name.include?('//')
      scraper = SplitCardScraper.new(multiverse_id, page, set)

    # Both Flip and DoubleFaced cards will display two images on the pages
    elsif page.css('img[id$="cardImage"]').count > 1
      mana_costs = scraper.containers.map do |container|
        container.css('[id$="manaRow"] .value img').map do |symbol|
          CardScraper.translate_mana_symbol(symbol)
        end.join
      end
      # Only one side of a DoubleFaced card will have a mana cost.
      # ... or zero, in the case of Westvale Abbey.
      if mana_costs.select(&:present?).count < 2
        scraper = DoubleFacedCardScraper.new(multiverse_id, page)
      else
        scraper = FlipCardScraper.new(multiverse_id, page)
      end
    end

    scraper.as_json
  rescue => e
    puts "FAILED ON #{multiverse_id}: #{e}"
  end
end

SETS_TO_DUMP.each do |set|
  if set['code'] == 'ath'; multiverse_ids = ([*1..87]-[18,80]).map{|i| "ath##{i}"}; else

  # Cookie contains setting to retrieve all results in a single page, instead of the default 100 results per page.
  gatherer_set_name = SET_NAME_OVERRIDES.invert[set['name']] || set['name']
  gatherer_set_name = 'Commander 2014' if gatherer_set_name == 'Commander 2014 Edition' # hardcoded so it works. lazy.
  set_url = "http://gatherer.wizards.com/Pages/Search/Default.aspx?sort=cn+&output=compact&set=[%22#{gatherer_set_name}%22]"
  cookie = "CardDatabaseSettings=0=1&1=28&2=0&14=1&3=13&4=0&5=1&6=15&7=0&8=1&9=1&10=19&11=7&12=8&15=1&16=0&13=;"
  response = get(set_url, "Cookie" => cookie)

  multiverse_ids = response.css('.cardItem [id$="cardPrintings"] a').map do |link|
    link.attr(:href)[/multiverseid=(\d+)/, 1].to_i
  end.uniq - EXCLUDED_MULTIVERSE_IDS; end # end ath exception

  # s00#13 is missing from Gatherer. This will pull the data from CARD_JSON_OVERRIDES
  multiverse_ids << 's00#13' if set['code'] == 's00'

  worker_pool = CelluloidWorker.pool(size: WORKER_POOL_SIZE)
  card_json = multiverse_ids.map do |multiverse_id|
    worker_pool.future.fetch_data(multiverse_id, set)
  end.map(&:value).flatten.compact

  # Output is sorted the same as search results, by collector num.
  write File.join(CARD_JSON_FILE_PATH, "#{set['code']}.json"), card_json
end
