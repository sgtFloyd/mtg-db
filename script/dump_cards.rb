# encoding: UTF-8
require_relative './script_util.rb'
require_relative './dump_images.rb'

ADDITIONAL_CARDS = MultiJson.load(DATA)
FILE_PATH = File.expand_path('../../data/cards.json', __FILE__)
def key(card_json); [card_json['set_name'], card_json['collector_num']]; end

def merge(data)
  existing = Hash[read(FILE_PATH).map{|c| [key(c), c]}]
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

  def collector_num
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
  cards << cnums.map{|n| CardPage.new(set, n).as_json}.compact
  if ADDITIONAL_CARDS.include?(set['mgci_code'])
    cards << ADDITIONAL_CARDS[set['mgci_code']]
  end
end

write FILE_PATH, merge(cards.flatten)

sets.each do |set|
  next if ARGV[0] && ARGV[0] != set['mgci_code']
  ImageDumper.new(set['mgci_code']).run
end

# DATA: additional cards not found in mgci
__END__
{
  "ori": [
    {
      "name": "Aegis Angel",
      "set_name": "Magic Origins",
      "collector_num": "273",
      "illustrator": "Aleksi Briclot",
      "types": [
        "Creature"
      ],
      "supertypes": [],
      "subtypes": [
        "Angel"
      ],
      "rarity": "Rare",
      "mana_cost": "4WW",
      "converted_mana_cost": 6,
      "oracle_text": [
        "Flying (This creature can't be blocked except by creatures with flying or reach.)",
        "When Aegis Angel enters the battlefield, another target permanent gains indestructible for as long as you control Aegis Angel. (Effects that say \"destroy\" don't destroy it. A creature with indestructible can't be destroyed by damage.)"
      ],
      "flavor_text": null,
      "power": "5",
      "toughness": "5",
      "loyalty": null,
      "multiverse_id": 401452,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Divine Verdict",
      "set_name": "Magic Origins",
      "collector_num": "274",
      "illustrator": "Kev Walker",
      "types": [
        "Instant"
      ],
      "supertypes": [],
      "subtypes": [],
      "rarity": "Common",
      "mana_cost": "3W",
      "converted_mana_cost": 4,
      "oracle_text": [
        "Destroy target attacking or blocking creature."
      ],
      "flavor_text": "\"Guilty.\"",
      "power": null,
      "toughness": null,
      "loyalty": null,
      "multiverse_id": 401453,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Eagle of the Watch",
      "set_name": "Magic Origins",
      "collector_num": "275",
      "illustrator": "Scott Murphy",
      "types": [
        "Creature"
      ],
      "supertypes": [],
      "subtypes": [
        "Bird"
      ],
      "rarity": "Common",
      "mana_cost": "2W",
      "converted_mana_cost": 3,
      "oracle_text": [
        "Flying, vigilance"
      ],
      "flavor_text": "\"Even from miles away, I could see our eagles circling. That's when I gave the command to pick up the pace. I knew we were needed at home.\"—Kanlos, Akroan captain",
      "power": "2",
      "toughness": "1",
      "loyalty": null,
      "multiverse_id": 401454,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Serra Angel",
      "set_name": "Magic Origins",
      "collector_num": "276",
      "illustrator": "Greg Staples",
      "types": [
        "Creature"
      ],
      "supertypes": [],
      "subtypes": [
        "Angel"
      ],
      "rarity": "Uncommon",
      "mana_cost": "3WW",
      "converted_mana_cost": 5,
      "oracle_text": [
        "Flying (This creature can't be blocked except by creatures with flying or reach.)",
        "Vigilance (Attacking doesn't cause this creature to tap.)"
      ],
      "flavor_text": "Follow the light. In its absence, follow her.",
      "power": "4",
      "toughness": "4",
      "loyalty": null,
      "multiverse_id": 401455,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Into the Void",
      "set_name": "Magic Origins",
      "collector_num": "277",
      "illustrator": "Daarken",
      "types": [
        "Sorcery"
      ],
      "supertypes": [],
      "subtypes": [],
      "rarity": "Uncommon",
      "mana_cost": "3U",
      "converted_mana_cost": 4,
      "oracle_text": [
        "Return up to two target creatures to their owners' hands."
      ],
      "flavor_text": "\"The cathars have their swords, the inquisitors their axes. I prefer the ‘diplomatic' approach.\"—Terhold, archmage of Drunau",
      "power": null,
      "toughness": null,
      "loyalty": null,
      "multiverse_id": 401456,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Mahamoti Djinn",
      "set_name": "Magic Origins",
      "collector_num": "278",
      "illustrator": "Greg Staples",
      "types": [
        "Creature"
      ],
      "supertypes": [],
      "subtypes": [
        "Djinn"
      ],
      "rarity": "Rare",
      "mana_cost": "4UU",
      "converted_mana_cost": 6,
      "oracle_text": [
        "Flying (This creature can't be blocked except by creatures with flying or reach.)"
      ],
      "flavor_text": "Of royal blood among the spirits of the air, the Mahamoti djinn rides on the wings of the winds. As dangerous in the gambling hall as he is in battle, he is a master of trickery and misdirection.",
      "power": "5",
      "toughness": "6",
      "loyalty": null,
      "multiverse_id": 401457,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Weave Fate",
      "set_name": "Magic Origins",
      "collector_num": "279",
      "illustrator": "Zack Stella",
      "types": [
        "Instant"
      ],
      "supertypes": [],
      "subtypes": [],
      "rarity": "Common",
      "mana_cost": "3U",
      "converted_mana_cost": 4,
      "oracle_text": [
        "Draw two cards."
      ],
      "flavor_text": "Destiny is a flickering path among tangles possibilities.",
      "power": null,
      "toughness": null,
      "loyalty": null,
      "multiverse_id": 401458,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Flesh to Dust",
      "set_name": "Magic Origins",
      "collector_num": "280",
      "illustrator": "Julie Dillon",
      "types": [
        "Instant"
      ],
      "supertypes": [],
      "subtypes": [],
      "rarity": "Common",
      "mana_cost": "3BB",
      "converted_mana_cost": 5,
      "oracle_text": [
        "Destroy target creature. It can't be regenerated."
      ],
      "flavor_text": "\"Another day. Another avenging angel. Another clump of feathers to toss in the trash.\"—Liliana Vess",
      "power": null,
      "toughness": null,
      "loyalty": null,
      "multiverse_id": 401459,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Mind Rot",
      "set_name": "Magic Origins",
      "collector_num": "281",
      "illustrator": "Steve Luke",
      "types": [
        "Sorcery"
      ],
      "supertypes": [],
      "subtypes": [],
      "rarity": "Common",
      "mana_cost": "2B",
      "converted_mana_cost": 3,
      "oracle_text": [
        "Target player discards two cards."
      ],
      "flavor_text": "\"It saddens me to lose a source of inspiration. This one seemed especially promising.\"—Ashiok",
      "power": null,
      "toughness": null,
      "loyalty": null,
      "multiverse_id": 401460,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Nightmare",
      "set_name": "Magic Origins",
      "collector_num": "282",
      "illustrator": "Vance Kovacs",
      "types": [
        "Creature"
      ],
      "supertypes": [],
      "subtypes": [
        "Nightmare",
        "Horse"
      ],
      "rarity": "Rare",
      "mana_cost": "5B",
      "converted_mana_cost": 6,
      "oracle_text": [
        "Flying (This creature can't be blocked except by creatures with flying or reach.)",
        "Nightmare's power and toughness are each equal to the number of Swamps you control."
      ],
      "flavor_text": "The thunder of its hooves beats dreams into despair.",
      "power": "*",
      "toughness": "*",
      "loyalty": null,
      "multiverse_id": 401461,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Sengir Vampire",
      "set_name": "Magic Origins",
      "collector_num": "283",
      "illustrator": "Kev Walker",
      "types": [
        "Creature"
      ],
      "supertypes": [],
      "subtypes": [
        "Vampire"
      ],
      "rarity": "Uncommon",
      "mana_cost": "3BB",
      "converted_mana_cost": 5,
      "oracle_text": [
        "Flying (This creature can't be blocked except by creatures with flying or reach.)",
        "Whenever a creature dealt damage by Sengir Vampire this turn dies, put a +1/+1 counter on Sengir Vampire."
      ],
      "flavor_text": "Empires rise and fall, but evil is eternal.",
      "power": "4",
      "toughness": "4",
      "loyalty": null,
      "multiverse_id": 401462,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Fiery Hellhound",
      "set_name": "Magic Origins",
      "collector_num": "284",
      "illustrator": "Ted Galaday",
      "types": [
        "Creature"
      ],
      "supertypes": [],
      "subtypes": [
        "Elemental",
        "Hound"
      ],
      "rarity": "Common",
      "mana_cost": "1RR",
      "converted_mana_cost": 3,
      "oracle_text": [
        "{R}: Fiery Hellhound gets +1/+0 until end of turn."
      ],
      "flavor_text": "\"I had hoped to instill in it the loyalty of a guard dog, but with fire's power comes its unpredictability.\"—Maggath, Sardian elementalist",
      "power": "2",
      "toughness": "2",
      "loyalty": null,
      "multiverse_id": 401463,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Shivan Dragon",
      "set_name": "Magic Origins",
      "collector_num": "285",
      "illustrator": "Donato Giancola",
      "types": [
        "Creature"
      ],
      "supertypes": [],
      "subtypes": [
        "Dragon"
      ],
      "rarity": "Rare",
      "mana_cost": "4RR",
      "converted_mana_cost": 6,
      "oracle_text": [
        "Flying (This creature can't be blocked except by creatures with flying or reach.)",
        "{R}: Shivan Dragon gets +1/+0 until end of turn."
      ],
      "flavor_text": "The undisputed master of the mountains of Shiv.",
      "power": "5",
      "toughness": "5",
      "loyalty": null,
      "multiverse_id": 401464,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Plummet",
      "set_name": "Magic Origins",
      "collector_num": "286",
      "illustrator": "Pete Venters",
      "types": [
        "Instant"
      ],
      "supertypes": [],
      "subtypes": [],
      "rarity": "Common",
      "mana_cost": "1G",
      "converted_mana_cost": 2,
      "oracle_text": [
        "Destroy target creature with flying."
      ],
      "flavor_text": "\"Let nothing own the skies but the wind.\"—Dejara, Giltwood druid",
      "power": null,
      "toughness": null,
      "loyalty": null,
      "multiverse_id": 401465,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Prized Unicorn",
      "set_name": "Magic Origins",
      "collector_num": "287",
      "illustrator": "Sam Wood",
      "types": [
        "Creature"
      ],
      "supertypes": [],
      "subtypes": [
        "Unicorn"
      ],
      "rarity": "Uncommon",
      "mana_cost": "3G",
      "converted_mana_cost": 4,
      "oracle_text": [
        "All creatures able to block Prized Unicorn do so."
      ],
      "flavor_text": "\"The desire for its magic horn inspires such bloodthirsty greed that all who see the unicorn will kill to possess it.\"—Dionus, elvish archdruid",
      "power": "2",
      "toughness": "2",
      "loyalty": null,
      "multiverse_id": 401466,
      "other_part": null,
      "color_indicator": null
    },
    {
      "name": "Terra Stomper",
      "set_name": "Magic Origins",
      "collector_num": "288",
      "illustrator": "Goran Josic",
      "types": [
        "Creature"
      ],
      "supertypes": [],
      "subtypes": [
        "Beast"
      ],
      "rarity": "Rare",
      "mana_cost": "3GGG",
      "converted_mana_cost": 6,
      "oracle_text": [
        "Terra Stomper can't be countered.",
        "Trample (If this creature would assign enough damage to its blockers to destroy them, you may have it assign the rest of its damage to defending player or planeswalker.)"
      ],
      "flavor_text": "Sometimes violent earthquakes, hurtling boulders, and unseasonable dust storms are wrongly attributed to the Roil.",
      "power": "8",
      "toughness": "8",
      "loyalty": null,
      "multiverse_id": 401467,
      "other_part": null,
      "color_indicator": null
    }
  ]
}
