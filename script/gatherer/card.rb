class GathererCard
  attr_accessor :multiverse_id
  def initialize(multiverse_id); self.multiverse_id = multiverse_id; end
  def self.dump(multiverse_id); self.new(multiverse_id).as_json; end

  def as_json(options={})
    return CARD_JSON_OVERRIDES[multiverse_id] if multiverse_id.in?(CARD_JSON_OVERRIDES)
    Gatherer.card_for(multiverse_id).as_json
  rescue => e
    puts "FAILED ON #{multiverse_id}: #{e}"
    puts e.backtrace.join("\n\t")
  end
end
