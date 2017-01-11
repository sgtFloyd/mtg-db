# Meld cards very-closely resemble Flip cards
class MeldCard < FlipCard

  def parse_collector_num
    # Use standard numbering for "front side" of meld cards
    return super if self.container_index == 0
    other_cnum = other_container.css("[id$=\"numberRow\"] .value").text.strip
    other_cnum.gsub('a', 'b') # Second container is always b-side of meld
  end

  # Similar to double-faced cards, the flavor text on meld cards is
  # formatted differently from every other card.
  def parse_flavor_text
    return FLAVOR_TEXT_OVERRIDES[self.multiverse_id] if FLAVOR_TEXT_OVERRIDES[self.multiverse_id]
    textboxes = container.css('[id$="flavorRow"] .cardtextbox')
    textboxes.map{|t| t.text.strip}.select(&:present?).join("\n").presence
  end

  MELD_MULTIVERSE_ID = {
    414304 => 414305, # Bruna, the Fading Light  => Brisela, Voice of Nightmares
    414319 => 414305, # Gisela, the Broken Blade => Brisela, Voice of Nightmares
    414386 => 414392, # Graf Rats                => Chittering Host
    414391 => 414392, # Midnight Scavengers      => Chittering Host
    414428 => 414429, # Hanweir Garrison         => Hanweir, the Writhing Township
    414511 => 414429, # Hanweir Battlements      => Hanweir, the Writhing Township
  }
  def as_json(options={})
    return super unless self.container_index.blank?
    [ self.class.new(self.multiverse_id, self.page, 0),
      self.class.new(MELD_MULTIVERSE_ID[self.multiverse_id], self.page, 1) ].map(&:as_json)
  end

end
