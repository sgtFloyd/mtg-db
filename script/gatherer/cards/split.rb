class SplitCard < StandardCard
  attr_accessor :overload_id, :container_index

  def initialize(multiverse_id, page, overload_id, container_index=nil)
    super(multiverse_id, page)
    self.overload_id = overload_id
    self.container_index = container_index
  end

  memo def parse_name
    if self.overload_id
      # Coerce gatherer naming scheme "Fire // Ice" into ours "Fire (Fire/Ice)"
      # using container_index to determine which half we're dealing with
      gatherer_name = self.page.css('[id$="subtitleDisplay"]').text.strip
      names = gatherer_name.split(' // ')
      "#{labeled_row(:name)} (#{names.join('/')})"
    else
      # APC and INV have their names hard-coded, as Gatherer doesn't give any
      # indication of which muiltiverse_id is associated with each half. Other
      # sets don't have this prople because both halves share the same
      # multiverse_id (overloaded_id = true).
      SPLIT_CARD_NAMES[multiverse_id] || (raise "Unknown split card: #{multiverse_id}")
    end
  end

  memo def parse_collector_num
    cnum = labeled_row(:number).gsub(/[^\d]/, '')
    first_name = parse_name.scan(/\(([^\/]+)/).flatten.first
    # Split cards share the same collector num. Number the first half as "a"
    # and the second half as "b".
    expected_name == first_name ? "#{cnum}a" : "#{cnum}b"
  end

  # Alter full name, replacing expected_name with other_name
  def parse_other_part
    both_names = parse_name.scan(/\(([^)]+)\)/).flatten.first
    other_name = both_names.gsub(expected_name, '').gsub(/\//, '')
    "#{other_name} (#{both_names})"
  end

  def as_json(options={})
    if self.overload_id && self.container_index.blank?
      # Assumes split cards will only ever have two parts.
      [ self.class.new(self.multiverse_id, self.page, self.overload_id, 0),
        self.class.new(self.multiverse_id, self.page, self.overload_id, 1)
      ].map(&:as_json)
    else
      super.merge('other_part' => parse_other_part)
    end
  end

  # Remove split name from parse_name, "Fire (Fire/Ice)" => "Fire"
  memo def expected_name
    parse_name.gsub(/\s+\([^)]*\)/, '')
  end

  # Grab the .cardComponentContainer that corresponds with this card. Ensure
  # the name displayed in the container matches the name in SPLIT_CARD_NAMES.
  memo def container
    # For overloaded split cards, we need to specify the container_index,
    # as the "subtitle display" (parse_name) isn't always accurate.
    return containers[self.container_index] if self.container_index.present?
    containers.find do |container|
      container.css('[id$="nameRow"] .value').text.strip == expected_name
    end
  end
end
