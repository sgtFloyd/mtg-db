require_relative './script_util.rb'

ALL_SETS = read(SET_JSON_FILE_PATH)
SETS_TO_DUMP = ARGV.any? ? ALL_SETS.select{|s| s['code'].in? ARGV} : ALL_SETS

class CardScraper
  extend Memoizer
  attr_accessor :multiverse_id, :set_name

  def initialize(multiverse_id, set_name)
    self.multiverse_id = multiverse_id
    self.set_name = set_name
  end

  SUPERTYPES = %w[Basic Legendary World Snow]
  memo def parse_types
    type_str = page.css('[id$="typeRow"] .value').text.strip
    { types:      type_str.split("—").map(&:strip)[0].split(' ') - SUPERTYPES,
      supertypes: type_str.split("—").map(&:strip)[0].split(' ') & SUPERTYPES,
      subtypes:   (type_str.split("—").map(&:strip)[1].split(' ') rescue []) }
  end

  def parse_oracle_text
    # TODO: Replace mana symbols with encoded values.
    page.css('[id$="textRow"] .cardtextbox').map(&:text).map(&:strip)
  end

  memo def parse_pt
    pt_str = page.css('[id$="ptRow"] .value').text.strip
    if parse_types[:types].include?('Planeswalker')
      { loyalty: pt_str }
    elsif parse_types[:types].include?('Creature')
      { power:     pt_str.split('/')[0].strip,
        toughness: pt_str.split('/')[1].strip }
    else
      {}
    end
  end

  def as_json(options={})
    {
      'name'                => page.css('[id$="nameRow"] .value').text.strip,
      'set_name'            => set_name,
      'collector_num'       => page.css('[id$="numberRow"] .value').text.strip,
      'illustrator'         => page.css('[id$="artistRow"] .value').text.strip,
      'types'               => parse_types[:types],
      'supertypes'          => parse_types[:supertypes],
      'subtypes'            => parse_types[:subtypes],
      'rarity'              => page.css('[id$="rarityRow"] .value').text.strip,
      'mana_cost'           => nil,
      'converted_mana_cost' => page.css('[id$="cmcRow"] .value').text.strip.to_i,
      'oracle_text'         => parse_oracle_text,
      'flavor_text'         => page.css('[id$="flavorRow"] .value').text.strip.presence,
      'power'               => parse_pt[:power],
      'toughness'           => parse_pt[:toughness],
      'loyalty'             => parse_pt[:loyalty],
      'multiverse_id'       => multiverse_id,
      'other_part'          => nil, # TODO: Handle split/flip/transform cards
      'color_indicator'     => page.css('[id$="colorIndicatorRow"] .value').text.strip.presence,
    }
    require 'pry'; binding.pry
  end

private
  def page
    @page ||= get("http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=#{self.multiverse_id}")
  end
end


class CelluloidWorker
  include Celluloid

  def fetch_data(multiverse_id, set_name)
    card = CardScraper.new(multiverse_id, set_name)
    card.as_json
  end
end

SETS_TO_DUMP.each do |set|
  set_url = "http://gatherer.wizards.com/Pages/Search/Default.aspx?sort=cn+&output=compact&set=[%22#{set['name']}%22]"
  cookie = "CardDatabaseSettings=0=1&1=28&2=0&14=1&3=13&4=0&5=1&6=15&7=0&8=1&9=1&10=19&11=7&12=8&15=1&16=0&13=;"
  response = get(set_url, "Cookie" => cookie)

  multiverse_ids = response.css('.cardItem [id$="cardTitle"]').map do |link|
    link.attr(:href)[/multiverseid=(\d+)/, 1].to_i
  end

  worker_pool = CelluloidWorker.pool(size: 1)
  card_json = multiverse_ids.map do |multiverse_id|
    worker_pool.future.fetch_data(multiverse_id, set['name'])
  end.map(&:value)
end
