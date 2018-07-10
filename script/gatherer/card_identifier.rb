class CardIdentifier
  attr_accessor :multiverse_id, :page, :default_card
  def initialize(multiverse_id, page)
    self.multiverse_id = multiverse_id
    self.page = page
    self.default_card = StandardCard.new(multiverse_id, page)
  end

  # Split cards are displayed as "Fire // Ice"
  def split?
    two_up? && self.default_card.parse_name.include?('//')
  end

  # Most sets assign the same multiverse_id to both halves of a split card,
  # "overloading" the id. apc and inv assign a unique multiverse_id to each half
  def split_overload?
    !self.default_card.parse_set_name.in?(['Apocalypse', 'Invasion'])
  end

  # At most one side of a double-faced card will have a mana cost.
  def double_faced?
    two_up? && mana_costs_shown.select(&:present?).count < 2
  end

  # Battlebond partners otherwise look like flip cards.
  def partners?
    PARTNER_CARD_NAMES.include?(multiverse_id.to_i)
  end

  # Both sides of a flip card will have a mana cost.
  def flip?
    two_up? && mana_costs_shown.select(&:present?).count == 2
  end

  # Meld cards look like double-faced cards, but a "Linked Card" is present
  def meld?
    double_faced? && linked_card_present?
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

  def linked_card_present?
    self.default_card.containers.any? do |container|
      container.css('[id$="linkedRow"] .value').present?
    end
  end
end
