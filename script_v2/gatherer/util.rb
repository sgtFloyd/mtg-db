require_relative 'cards/standard.rb'
require_relative 'cards/double_faced.rb'
require_relative 'cards/flip.rb'
require_relative 'cards/split.rb'
require_relative 'card_identifier.rb'

# Gatherer-specific utilities
class Gatherer
  # Cookie contains setting to retrieve all results in a single page, instead of the default 100 results per page.
  COOKIE = "CardDatabaseSettings=0=1&1=28&2=0&14=1&3=13&4=0&5=1&6=15&7=0&8=1&9=1&10=19&11=7&12=8&15=1&16=0&13=;"

  # Return the Gatherer URL for a given card or set.
  def self.url(for_card: nil, for_set: nil)
    if for_card
      "http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=#{for_card}"
    elsif for_set
      # TODO: Append &action=advanced&special=true to return Conspiracies, Schemes, etc.
      "http://gatherer.wizards.com/Pages/Search/Default.aspx?sort=cn+&output=compact&set=[%22#{for_set}%22]"
    else
      "http://gatherer.wizards.com/Pages/Default.aspx"
    end
  end

  # Return the proper Card representing a given card's layout
  def self.card_for(multiverse_id)
    page = get url(for_card: multiverse_id)
    card = CardIdentifier.new(multiverse_id, page)

    if card.split?
      SplitCard.new(multiverse_id, page, card.split_overload?)
    elsif card.double_faced?
      DoubleFacedCard.new(multiverse_id, page)
    elsif card.flip?
      FlipCard.new(multiverse_id, page)
    else
      StandardCard.new(multiverse_id, page)
    end
  end

  # Get all set names from Gatherer's search dropdown.
  def self.scrape_set_names
    get(url).css('select[name$="setAddText"] option').map(&:text)
      .reject(&:empty?).reject{|name| name.in?(EXCLUDED_SETS)}
  end

  # Get all multiverse_ids from a set's search result page.
  def self.scrape_multiverse_ids(set_name)
    set_name = translate_set_name(set_name)
    response = get(url(for_set: set_name), "Cookie" => COOKIE)
    multiverse_ids = response.css('.cardItem [id$="cardPrintings"] a').map do |link|
      link.attr(:href)[/multiverseid=(\d+)/, 1].to_i
    end.uniq - EXCLUDED_MULTIVERSE_IDS

    # s00#13 is missing from Gatherer. This will pull the data from CARD_JSON_OVERRIDES
    multiverse_ids << 's00#13' if set_name == 'Starter 2000'

    # CNS 1-13 (Conspiracies) missing from standard search, but multiverse_ids exist
    if set_name == 'Magic: The Gathering—Conspiracy'
      multiverse_ids = [382222, 382253, 382289, 382315, 382360, 382393, 382411,
        382356, 382206, 382292, 382355, 382216, 382332] + multiverse_ids
    # CN2 1-12 (Conspiracies) missing from standard search, but multiverse_ids exist
    elsif set_name == 'Conspiracy: Take the Crown'
      multiverse_ids = [416758, 416759, 416760, 416761, 416762, 416763, 416764,
        416765, 416766, 416767, 416768, 416769] + multiverse_ids
    end
    multiverse_ids
  end

  def self.translate_set_name(their_name)
    our_name = SET_NAME_OVERRIDES.invert[their_name] || their_name
    our_name = 'Commander 2014' if our_name == 'Commander 2014 Edition' # hardcoded so it works. lazy.
    our_name
  end

  def self.translate_card_types(type_str)
    card_types = type_str.split("—").map(&:strip)
    { types:      (card_types[0].split(' ') - CARD_SUPERTYPES),
      supertypes: (card_types[0].split(' ') & CARD_SUPERTYPES),
      subtypes:   (card_types[1].gsub("’", "'").split(' ') rescue []) }
  end

  # Translate Gatherer's <img> mana symbols to our encoded representation
  def self.translate_mana_symbol(symbol)
    symbol_key = symbol.attr(:alt).strip
    MANA_COST_SYMBOLS[symbol_key] || symbol_key
  end

  # Translate multiple textboxes into an array of oracle text. Convert images
  # (mana symbols, tap, etc.) into our encoded representation.
  def self.translate_oracle_text(textboxes)
    textboxes.map do |textbox|
      textbox.css(:img).each do |img|
        symbol = self.translate_mana_symbol(img)
        symbol = "{#{symbol}}" unless symbol.match(/^{/)
        img.replace(symbol)
      end
      # Gatherer messes up {10} formatting, resulting in {1}0
      textbox.text.strip.gsub('{1}0', '{10}')
    end.select(&:present?)
  end

end
