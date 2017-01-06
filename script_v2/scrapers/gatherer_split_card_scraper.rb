class GathererSplitCardScraper < GathererCardScraper
  attr_accessor :given_set, :container_index

  def initialize(multiverse_id, page, given_set, container_index=nil)
    super(multiverse_id, page)
    self.given_set = given_set
    self.container_index = container_index
  end

  memo def parse_name
    if overload_multiverse_id?
      # Coerce gatherer naming scheme "Fire // Ice" into ours "Fire (Fire/Ice)"
      # using container_index to determine which half we're dealing with
      gatherer_name = page.css('[id$="subtitleDisplay"]').text.strip
      names = gatherer_name.split(' // ')
      "#{labeled_row(:name)} (#{names.join('/')})"
    else
      SPLIT_CARD_NAMES[multiverse_id] || (raise "Unknown split card: #{multiverse_id}")
    end
  end

  memo def parse_collector_num
    cnum = labeled_row(:number).gsub(/[^\d]/, '')
    first_name = parse_name.scan(/\(([^\/]+)/).flatten.first
    expected_name == first_name ? "#{cnum}a" : "#{cnum}b"
  end

  # Alter full name, replacing expected_name with other_name
  def parse_other_part
    both_names = parse_name.scan(/\(([^)]+)\)/).flatten.first
    other_name = both_names.gsub(expected_name, '').gsub(/\//, '')
    "#{other_name} (#{both_names})"
  end

  def as_json(options={})
    if overload_multiverse_id? && !self.container_index.present?
      containers.map.with_index do |_, i|
        GathererSplitCardScraper.new(multiverse_id, page, given_set, i).as_json
      end
    else
      super.merge('other_part' => parse_other_part)
    end
  end

  # Most sets assign the same multiverse_id to both halves of a split card,
  # "overloading" the id. Others assign a unique multiverse_id to each half.
  SETS_WITHOUT_OVERLOADED_MULTIVERSE_IDS = ['Apocalypse', 'Invasion']
  memo def overload_multiverse_id?
    !self.given_set['name'].in? SETS_WITHOUT_OVERLOADED_MULTIVERSE_IDS
  end

  # Remove split name from parse_name, "Fire (Fire/Ice)" => "Fire"
  memo def expected_name
    parse_name.gsub(/\s+\([^)]*\)/, '')
  end

  # Grab the .cardComponentContainer that corresponds with this card. Ensure
  # the name displayed in the container matches the name in SPLIT_CARD_NAMES.
  memo def container
    return containers[self.container_index] if self.container_index.present?
    containers.find do |container|
      container.css('[id$="nameRow"] .value').text.strip == expected_name
    end
  end
end
