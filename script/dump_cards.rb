# encoding: UTF-8
require_relative './script_util.rb'
require_relative './dump_images.rb'

DATA_FOLDER = File.expand_path('../../data', __FILE__)
CARD_JSON = File.join(DATA_FOLDER, 'cards.json')
MISSING_JSON = MultiJson.load(File.read(File.join(DATA_FOLDER, 'missing.json'))) # additional cards not found in mgci
def key(card_json); [card_json['set_name'], card_json['collector_num']]; end

def merge(data)
  existing = Hash[read(CARD_JSON).map{|c| [key(c), c]}]
  data.each do |card|
    existing[key(card)] = (existing[key(card)] || {}).merge(card)
  end
  existing.values
end

def sets
  read File.expand_path('../../data/sets.json', __FILE__)
end

def extract_cnums(set_code)
  spoiler = get "http://magiccards.info/#{ set_code }/en.html"
  links = spoiler.css("td a[href*=\"/#{ set_code }/en/\"]")
  links.map{|link|
    href = link.attributes['href'].value
    href.split(/[\.\/]/)[-2]
  }
end

class CardPage
  def initialize(set, num)
    @set_name = set['name']
    @set_code = set['mgci_code']
    @collector_num = num
  end

  COLLECTOR_NUM_OVERRIDES = {
    407693 => '183a',
    407695 => '184a'
  }
  def collector_num
    return COLLECTOR_NUM_OVERRIDES[multiverse_id] if COLLECTOR_NUM_OVERRIDES.include?(multiverse_id)

    # ZEN lands paired using the official 246/246a numbering rather than mgci's 246/266
    if @set_name == 'Zendikar' && @collector_num.to_i > 249
      "#{@collector_num.to_i-20}a"
    else
      @collector_num
    end
  end
  def mana_cost
    @_center_p_first ||= center_div.css('p:first').first.text rescue nil
    @mana_cost ||= @_center_p_first.to_s.split("\n").map{|s| s.strip.chomp(',')}[1].strip rescue nil

    if @mana_cost.empty?
      @converted_mana_cost ||= 0
      return nil
    elsif match = @mana_cost.match(/\((.+)\)/)
      @converted_mana_cost ||= match[1].to_i
      cost = @mana_cost.gsub(/\((.+)\)/, '').strip
      return cost.empty? ? nil : cost
    else
      @converted_mana_cost ||= 0
      return @mana_cost
    end
  end
  def cmc
    mana_cost; @converted_mana_cost
  end
  def multiverse_id
    @multiverse_id ||= center_div.css('a[href*="multiverseid"]').first.attr('href').split('=').last
    @multiverse_id == '0' ? nil : @multiverse_id.to_i
  end
  def name
    @_name ||= center_div.css("a[href=\"/#{@set_code}/en/#{@collector_num}.html\"]").first.text
    # Override for bad mgci data.
    return "Lim-Dûl's High Guard" if @_name == "Lim-Dul's High Guard"
    @_name
  end
  def power
    @power ||= p_t_str ? p_t_str.split('/')[0] : nil
  end
  def toughness
    @toughness ||= p_t_str ? p_t_str.split('/')[1] : nil
  end
  def loyalty
    type_str; @loyalty
  end
  def types
    @_super_and_types ||= type_str.split("—").map(&:strip)[0].split(' ')
    @types ||= @_super_and_types - SUPERTYPES
  end
  def subtypes
    @subtypes ||= type_str.split("—").map(&:strip)[1].split(' ') rescue nil
    @subtypes ||= []
  end
  SUPERTYPES = %w[Basic Legendary World Snow]
  def supertypes
    @_super_and_types ||= type_str.split("—").map(&:strip)[0].split(' ')
    @supertypes ||= (@_super_and_types & SUPERTYPES) || []
  end

  PLANESWALKER_TEXT_OVERRIDES = [398423, 398429, 398432, 398435, 398442]
  def oracle_text
    @_ctext ||= center_div.css('.ctext')
    @_ctext.css('br').each{|node| node.replace("\n")}
    @oracle_text ||= (@_ctext.text || "").strip.split("\n\n")
    return [] if @oracle_text.empty?
    # Slice Planeswalker abilities into multiple lines
    if PLANESWALKER_TEXT_OVERRIDES.include?(multiverse_id)
      @oracle_text = @oracle_text.join.gsub('−','-').split(/(?=[-+0][\dX]*:\s)/)
    end
    @oracle_text
  end
  def flavor_text
    @flavor_text ||= center_div.css('p')[-3].text
    @flavor_text.empty? ? nil : @flavor_text
  end
  def illustrator
    @illustrator ||= center_div.css('p')[-2].text.gsub(/^Illus. /, '')
    @illustrator.empty? ? nil : @illustrator
  end
  OTHER_PART_OVERRIDES = {
    398428 => "Gideon, Battle-Forged",
    398429 => "Kytheon, Hero of Akros",
    398434 => "Jace, Telepath Unbound",
    398435 => "Jace, Vryn's Prodigy",
    398441 => "Liliana, Defiant Necromancer",
    398442 => "Liliana, Heretical Healer",
    398422 => "Chandra, Roaring Flame",
    398423 => "Chandra, Fire of Kaladesh",
    398438 => "Nissa, Sage Animist",
    398432 => "Nissa, Vastwood Seer"
  }
  def other_part
    return OTHER_PART_OVERRIDES[multiverse_id] if OTHER_PART_OVERRIDES.include?(multiverse_id)
    page.css('u:contains("The other part is") ~ a').first.text rescue nil
  end
  def color_ind
    @_center_p_first ||= center_div.css('p:first').text rescue nil
    if match = @_center_p_first.match(/\(Color Indicator: (.*)\)/)
      return match[1]
    end
    nil
  end
  def rarity
    # Override for bad mgci data.
    return "Uncommon" if multiverse_id == 220502
    return "Special" if multiverse_id == 109704

    @_set_rarity ||= page.css('u:contains("Editions:") ~ b').first.text
    @rarity ||= @_set_rarity.match(/\((.+)\)/)[1]

    # Urza's Lands in MTGO Masters Edition IV are incorrectly marked as
    # having Basic Land rarity. They should be "Common"
    @rarity = 'Common' if @rarity == 'Land' && name.match("Urza's")

    @rarity
  end

  def type_str
    @_center_p_first ||= center_div.css('p:first').text rescue nil
    @_type_p_t ||= @_center_p_first.to_s.split("\n").map{|s| s.strip.chomp(',')}[0]
    @_type_str ||= @_type_p_t.split(' ').last.match('/') ? @_type_p_t.split(' ')[0..-2].join(' ') : @_type_p_t
    if matches = @_type_str.match(/\(Loyalty: (.+)\)/)
      @loyalty ||= matches[1]
      @_type_str = @_type_str.gsub(matches[0], '').strip
    end
    @_type_str
  end
  def p_t_str
    @_center_p_first ||= center_div.css('p:first').text rescue nil
    @_type_p_t ||= @_center_p_first.to_s.split("\n").map{|s| s.strip.chomp(',')}[0]
    @_type_p_t.split(' ').last.match('/') ? @_type_p_t.split(' ')[-1] : nil
  end

  def as_json
    return if types.include?('Token')
    {
      'name' => name,                     # Shouldn't be nil
      'set_name' => @set_name,            # Shouldn't be nil
      'collector_num' => collector_num,   # Shouldn't be nil
      'illustrator' => illustrator,       # Shouldn't be nil
      'types' => types,                   # Can't be nil. Can't be empty []
      'supertypes' => supertypes,         # Can't be nil. Can be empty []
      'subtypes' => subtypes,             # Can't be nil. Can be empty []
      'rarity' => rarity,                 # Can't be nil.
      'mana_cost' => mana_cost,           # Can be nil
      'converted_mana_cost' => cmc,       # Can't be nil. Can be 0
      'oracle_text' => oracle_text,       # Can't be nil. Can be empty []
      'flavor_text' => flavor_text,       # Can be nil
      'power' => power,                   # Can be nil
      'toughness' => toughness,           # Can be nil
      'loyalty' => loyalty,               # Can be nil
      'multiverse_id' => multiverse_id,   # Can be nil. Shouldn't be "0"
      'other_part' => other_part,         # Can be nil. Should be "Name of Card"
      'color_indicator' => color_ind      # Can be nil
    }
  end

private

  def page
    @_page ||= get "http://magiccards.info/#{@set_code}/en/#{@collector_num}.html"
  end

  def center_div
    @_center_div ||= page.css('td[valign="top"][width="70%"]').first
  end

  def right_div
    @_right_div ||= page.css('small').first
  end

end

cards = []
sets.each do |set|
  next if ARGV[0] && ARGV[0] != set['mgci_code']
  cnums = extract_cnums( set['mgci_code'] )
  cards << cnums.map{|n|
    CardPage.new(set, n).as_json
  }.compact
  if MISSING_JSON.include?(set['mgci_code'])
    cards << MISSING_JSON[set['mgci_code']]
  end
end

write CARD_JSON, merge(cards.flatten)

sets.each do |set|
  next if ARGV[0] && ARGV[0] != set['mgci_code']
  ImageDumper.new(set['mgci_code']).run
end
