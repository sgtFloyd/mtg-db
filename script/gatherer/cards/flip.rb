class FlipCard < StandardCard
  attr_accessor :container_index

  def initialize(multiverse_id, page, container_index=nil)
    super(multiverse_id, page)
    self.container_index = container_index
  end

  memo def parse_name
    labeled_row(:name).gsub("Æ", "Ae")
  end

  memo def parse_other_part
    other_container.css("[id$=\"nameRow\"] .value").text.strip
  end

  def as_json(options={})
    if self.container_index.blank?
      # Assumes flip cards will only ever have two parts.
      [ self.class.new(self.multiverse_id, self.page, 0),
        self.class.new(self.multiverse_id, self.page, 1) ].map(&:as_json)
    else
      super.merge('other_part' => parse_other_part)
    end
  end

  def container
    # We shouldn't be trying to access the container until we've selected a
    # side (via container_index), so don't worry about a fallback.
    containers[self.container_index]
  end

  def other_container
    # XOR to get the "other container's" index
    other_container = containers[1^self.container_index]
  end
end
