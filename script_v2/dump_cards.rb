require_relative './script_util.rb'

ALL_SETS = read(SET_JSON_FILE_PATH)
SETS_TO_DUMP = ARGV.any? ? ALL_SETS.select{|s| s['code'].in? ARGV} : ALL_SETS
WORKER_POOL_SIZE = 1

class CardScraper
  extend Memoizer
  attr_accessor :multiverse_id

  def initialize(multiverse_id)
    self.multiverse_id = multiverse_id
  end

  SUPERTYPES = %w[Basic Legendary World Snow]
  memo def parse_types
    { types:      labeledRow(:type).split("—").map(&:strip)[0].split(' ') - SUPERTYPES,
      supertypes: labeledRow(:type).split("—").map(&:strip)[0].split(' ') & SUPERTYPES,
      subtypes:   (labeledRow(:type).split("—").map(&:strip)[1].split(' ') rescue []) }
  end

  memo def parse_oracle_text
    textboxes = container.css('[id$="textRow"] .cardtextbox')
    textboxes.map do |textbox|
      textbox.css(:img).each do |img|
        img_alt = img.attr(:alt).strip
        symbol = MANA_COST_SYMBOLS[img_alt] || img_alt
        symbol = "{#{symbol}}" unless symbol.match(/^{/)
        img.replace(symbol)
      end
      textbox.text.strip
    end
  end

  memo def parse_pt
    if parse_types[:types].include?('Planeswalker')
      { loyalty: labeledRow(:pt) }
    elsif parse_types[:types].include?('Creature')
      { power:     labeledRow(:pt).split('/')[0].strip,
        toughness: labeledRow(:pt).split('/')[1].strip }
    else
      {}
    end
  end

  def parse_mana_cost
    container.css('[id$="manaRow"] .value img').map do |symbol|
      symbol_key = symbol.attr(:alt).strip
      MANA_COST_SYMBOLS[symbol_key] || symbol_key
    end.join
  end

  def as_json(options={})
    {
      'name'                => page.css('[id$="subtitleDisplay"]').text.strip,
      'set_name'            => labeledRow(:set),
      'collector_num'       => labeledRow(:number),
      'illustrator'         => labeledRow(:artist),
      'types'               => parse_types[:types],
      'supertypes'          => parse_types[:supertypes],
      'subtypes'            => parse_types[:subtypes],
      'rarity'              => labeledRow(:rarity),
      'mana_cost'           => parse_mana_cost,
      'converted_mana_cost' => labeledRow(:cmc).to_i,
      'oracle_text'         => parse_oracle_text,
      'flavor_text'         => labeledRow(:flavor).presence,
      'power'               => parse_pt[:power],
      'toughness'           => parse_pt[:toughness],
      'loyalty'             => parse_pt[:loyalty],
      'multiverse_id'       => multiverse_id,
      'other_part'          => nil,
      'color_indicator'     => labeledRow(:colorIndicator).presence,
    }
    require 'pry'; binding.pry
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

  memo def labeledRow(label)
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

  multiverse_ids = response.css('.cardItem [id$="cardTitle"]').map do |link|
    link.attr(:href)[/multiverseid=(\d+)/, 1].to_i
  end

  worker_pool = CelluloidWorker.pool(size: WORKER_POOL_SIZE)
  card_json = multiverse_ids.map do |multiverse_id|
    worker_pool.future.fetch_data(multiverse_id)
  end.map(&:value)
end
