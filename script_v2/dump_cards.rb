require_relative './script_util.rb'

ALL_SETS = read(SET_JSON_FILE_PATH)
SETS_TO_DUMP = ARGV.any? ? ALL_SETS.select{|s| s['code'].in? ARGV} : ALL_SETS
WORKER_POOL_SIZE = 25

class CardScraper
  extend Memoizer
  attr_accessor :multiverse_id

  def initialize(multiverse_id)
    self.multiverse_id = multiverse_id
  end

  memo def parse_name
    page.css('[id$="subtitleDisplay"]').text.strip
  end

  SUPERTYPES = %w[Basic Legendary World Snow]
  memo def parse_types
    { types:      labeled_row(:type).split("—").map(&:strip)[0].split(' ') - SUPERTYPES,
      supertypes: labeled_row(:type).split("—").map(&:strip)[0].split(' ') & SUPERTYPES,
      subtypes:   (labeled_row(:type).split("—").map(&:strip)[1].split(' ') rescue []) }
  end

  def parse_mana_cost
    container.css('[id$="manaRow"] .value img').map do |symbol|
      symbol_key = symbol.attr(:alt).strip
      MANA_COST_SYMBOLS[symbol_key] || symbol_key
    end.join
  end

  BASIC_LAND_SYMBOL = {'Plains'   => '{W}', 'Island' => '{U}', 'Swamp'  => '{B}',
                       'Mountain' => '{R}', 'Forest' => '{G}', 'Wastes' => '{C}'}
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
      textbox.text.strip
    end.select(&:present?)
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

  ILLUSTRATOR_REPLACEMENTS = {"Brian Snoddy" => "Brian Snõddy"}
  def parse_illustrator
    artist_str = labeled_row(:artist)
    ILLUSTRATOR_REPLACEMENTS[artist_str] || artist_str
  end

  RARITY_REPLACEMENTS = {'Basic Land' => 'Land'}
  def parse_rarity
    rarity_str = labeled_row(:rarity)
    RARITY_REPLACEMENTS[rarity_str] || rarity_str
  end

  def as_json(options={})
    {
      'name'                => parse_name,
      'set_name'            => labeled_row(:set),
      'collector_num'       => labeled_row(:number),
      'illustrator'         => parse_illustrator,
      'types'               => parse_types[:types],
      'supertypes'          => parse_types[:supertypes],
      'subtypes'            => parse_types[:subtypes],
      'rarity'              => parse_rarity,
      'mana_cost'           => parse_mana_cost.presence,
      'converted_mana_cost' => labeled_row(:cmc).to_i,
      'oracle_text'         => parse_oracle_text,
      'flavor_text'         => labeled_row(:flavor).presence,
      'power'               => parse_pt[:power],
      'toughness'           => parse_pt[:toughness],
      'loyalty'             => parse_pt[:loyalty],
      'multiverse_id'       => multiverse_id,
      'other_part'          => nil,
      'color_indicator'     => labeled_row(:colorIndicator).presence,
    }
  end

private
  memo def page
    get("http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=#{self.multiverse_id}")
  end

  # Grab the .cardComponentContainer that corresponds with this card. Flip,
  # split, and transform cards can have multiple containers on the page.
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


class CelluloidWorker
  include Celluloid

  def fetch_data(multiverse_id)
    CardScraper.new(multiverse_id).as_json
  end
end

SETS_TO_DUMP.each do |set|
  # Cookie contains setting to retrieve all results in a single page, instead of the default 100 results per page.
  set_url = "http://gatherer.wizards.com/Pages/Search/Default.aspx?sort=cn+&output=compact&set=[%22#{set['name']}%22]"
  cookie = "CardDatabaseSettings=0=1&1=28&2=0&14=1&3=13&4=0&5=1&6=15&7=0&8=1&9=1&10=19&11=7&12=8&15=1&16=0&13=;"
  response = get(set_url, "Cookie" => cookie)

  multiverse_ids = response.css('.cardItem [id$="cardPrintings"] a').map do |link|
    link.attr(:href)[/multiverseid=(\d+)/, 1].to_i
  end

  worker_pool = CelluloidWorker.pool(size: WORKER_POOL_SIZE)
  card_json = multiverse_ids.map do |multiverse_id|
    worker_pool.future.fetch_data(multiverse_id)
  end.map(&:value)

  # Output is sorted the same as search results, by collector num.
  write File.join(CARD_JSON_FILE_PATH, "#{set['code']}.json"), card_json
end
