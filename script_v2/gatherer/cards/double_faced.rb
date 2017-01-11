class DoubleFacedCard < StandardCard
  memo def parse_other_part
    containers.each do |container|
      container_name = container.css("[id$=\"nameRow\"] .value").text.strip
      return container_name if container_name != parse_name
    end
  end

  # For some reason, the flavor text on double-faced cards is formatted
  # differently from every other card.
  def parse_flavor_text
    return FLAVOR_TEXT_OVERRIDES[self.multiverse_id] if FLAVOR_TEXT_OVERRIDES[self.multiverse_id]
    textboxes = container.css('[id$="flavorRow"] .cardtextbox')
    textboxes.map{|t| t.text.strip}.select(&:present?).join("\n").presence
  end

  def as_json(options={})
    super.merge('other_part' => parse_other_part)
  end

  memo def container
    containers.find do |container|
      container.css('[id$="nameRow"] .value').text.strip == parse_name
    end
  end
end
