class StandardCard
  extend Memoizer
  attr_accessor :multiverse_id, :page

  def initialize(multiverse_id, page)
    self.multiverse_id = multiverse_id
    self.page = page
  end

  memo def parse_name
    name_str = self.page.css('[id$="subtitleDisplay"]').text.strip.gsub("Æ", "Ae")
    CARD_NAME_OVERRIDES[self.multiverse_id] || name_str
  end

  memo def parse_collector_num
    COLLECTOR_NUM_OVERRIDES[self.multiverse_id] || labeled_row(:number)
  end

  memo def parse_types
    Gatherer.translate_card_types labeled_row(:type)
  end

  memo def parse_set_name
    SET_NAME_OVERRIDES[labeled_row(:set)] || labeled_row(:set)
  end

  memo def parse_mana_cost
    container.css('[id$="manaRow"] .value img').map do |symbol|
      Gatherer.translate_mana_symbol(symbol)
    end.join
  end

  memo def parse_oracle_text
    # Override oracle text for basic lands.
    if parse_types[:supertypes].include?('Basic')
      return ["({T}: Add #{BASIC_LAND_SYMBOLS[parse_name]}.)"]
    end
    textboxes = container.css('[id$="textRow"] .cardtextbox')
    Gatherer.translate_oracle_text textboxes
  end

  memo def parse_flavor_text
    return FLAVOR_TEXT_OVERRIDES[self.multiverse_id] if FLAVOR_TEXT_OVERRIDES[self.multiverse_id]
    textboxes = container.css('[id$="flavorRow"] .flavortextbox')
    textboxes.map{|t| t.text.strip}.select(&:present?).join("\n").presence
  end

  memo def parse_pt
    if parse_types[:types].include?('Planeswalker')
      { loyalty: labeled_row(:pt).strip.presence }
    elsif parse_types[:types].include?('Creature') ||
            parse_types[:subtypes].include?('Vehicle')
      { power:     labeled_row(:pt).split('/')[0].strip,
        toughness: labeled_row(:pt).split('/')[1].strip }
    else
      {}
    end
  end

  # Rather than overriding based on multiverse_id, correct any obvious typos
  ILLUSTRATOR_REPLACEMENTS = {
    "Brian Snoddy" => "Brian Snõddy",
    "Parente & Brian Snoddy" => "Parente & Brian Snõddy",
    "ROn Spencer" => "Ron Spencer",
    "s/b Lie Tiu" => "Lie Tiu"
  }
  memo def parse_illustrator
    artist_str = labeled_row(:artist)
    ILLUSTRATOR_OVERRIDES[self.multiverse_id] ||
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

  def parse_rulings
    container.css("tr.post").map do |post|
      # "translate" text to parse <img> symbols into appropriate text shorthand
      post_text = Gatherer.translate_oracle_text(post.css("[id$=\"rulingText\"]"))[0]
      { 'date' => post.css("[id$=\"rulingDate\"]").text.strip,
        'text' => post_text }
    end
  end

  CARD_NAME_REPLACEMENTS = {
    'kongming, "sleeping dragon"' => 'Kongming, “Sleeping Dragon”',
    'pang tong, "young phoenix"' => 'Pang Tong, “Young Phoenix”',
    'will-o\'-the-wisp' => 'Will-o\'-the-Wisp'
  }
  def as_json(options={})
    return if parse_types[:types].include?('Token') ||
                parse_name.in?(EXCLUDED_TOKEN_NAMES)
    {
      'name'                => CARD_NAME_REPLACEMENTS[parse_name.downcase] || parse_name,
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
      'multiverse_id'       => self.multiverse_id,
      'other_part'          => nil, # only relevant for split, flip, etc.
      'color_indicator'     => parse_color_indicator,
      'rulings'             => parse_rulings,
    }
  end

  # Grab the .cardComponentContainer that corresponds with this card. Flip,
  # split, and transform cards override this method. It's possible we can
  # replace the whole thing with `containers.first` for StandardCards?
  def container
    containers.find do |container|
      subtitle_display = CARD_NAME_OVERRIDES[self.multiverse_id] ||
                          self.page.css('[id$="subtitleDisplay"]').text.strip
      container.css('[id$="nameRow"] .value').text.strip == subtitle_display
    end || containers.first
  end

  def containers
    self.page.css('.cardComponentContainer')
  end

  memo def labeled_row(label)
    container.css("[id$=\"#{label}Row\"] .value").text.strip
  end
end
