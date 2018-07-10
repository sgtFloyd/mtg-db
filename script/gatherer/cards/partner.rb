class PartnerCard < StandardCard
  def as_json(options = {})
    super.merge('other_part' => parse_other_part)
  end

  memo def parse_other_part
    containers.last.css("[id$=\"nameRow\"] .value").text.strip
  end

end
