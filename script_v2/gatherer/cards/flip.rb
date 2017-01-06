class FlipCard < StandardCard
  attr_accessor :container_index

  def initialize(multiverse_id, page, container_index=nil)
    super(multiverse_id, page)
    self.container_index = container_index
  end

  memo def parse_name
    labeled_row(:name)
  end

  memo def parse_other_part
    # Use xor to get the "other" container
    containers[1^self.container_index].css("[id$=\"nameRow\"] .value").text.strip
  end

  def as_json(options={})
    if !self.container_index.present?
      containers.map.with_index do |_, i|
        FlipCard.new(multiverse_id, page, i).as_json
      end
    else
      super.merge('other_part' => parse_other_part)
    end
  end

  def container
    # We shouldn't be trying to access the container until we've selected a
    # side (via container_index), so don't worry about a fallback.
    containers[self.container_index]
  end
end
