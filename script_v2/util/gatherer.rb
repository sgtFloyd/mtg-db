require_relative '../card_layouts/gatherer_standard_card.rb'
require_relative '../card_layouts/gatherer_double_faced_card.rb'
require_relative '../card_layouts/gatherer_flip_card.rb'
require_relative '../card_layouts/gatherer_split_card.rb'

class Gatherer; class << self

  # Return the proper Card representing a given card's layout
  def card_for(multiverse_id)
    page = get("http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=#{multiverse_id}")
    identifier = CardLayoutIdentifier.new(multiverse_id, page)

    if identifier.split_card?
      GathererSplitCard.new(multiverse_id, page, identifier.split_overload?)
    elsif identifier.double_faced_card?
      GathererDoubleFacedCard.new(multiverse_id, page)
    elsif identifier.flip_card?
      GathererFlipCard.new(multiverse_id, page)
    else
      GathererStandardCard.new(multiverse_id, page)
    end
  end

  # Translate Gatherer's <img> mana symbols to our representation
  def translate_mana_symbol(symbol)
    symbol_key = symbol.attr(:alt).strip
    MANA_COST_SYMBOLS[symbol_key] || symbol_key
  end

end; end

class CardLayoutIdentifier
  attr_accessor :multiverse_id, :page, :default_card
  def initialize(multiverse_id, page)
    self.multiverse_id = multiverse_id
    self.page = page
    self.default_card = GathererStandardCard.new(multiverse_id, page)
  end

  # Split cards are displayed as "Fire // Ice"
  def split_card?
    two_up? && self.default_card.parse_name.include?('//')
  end

  # Most sets assign the same multiverse_id to both halves of a split card,
  # "overloading" the id. apc and inv assign a unique multiverse_id to each half
  def split_overload?
    !self.default_card.parse_set_name.in?(['Apocalypse', 'Invasion'])
  end

  # At most one side of a double-faced card will have a mana cost.
  def double_faced_card?
    two_up? && mana_costs_shown.select(&:present?).count < 2
  end

  # Both sides of a flip card will have a mana cost.
  def flip_card?
    two_up? && mana_costs_shown.select(&:present?).count == 2
  end

private

  # Split, flip, and double-faced cards will display two images on the pages
  def two_up?
    self.page.css('img[id$="cardImage"]').count > 1
  end

  # Return all mana costs displayed on the page.
  def mana_costs_shown
    self.default_card.containers.map do |container|
      container.css('[id$="manaRow"] .value img').map do |symbol|
        Gatherer.translate_mana_symbol(symbol)
      end.join
    end
  end
end
