class GathererComment
  attr_accessor :container
  def initialize(container)
    self.container = container
  end

  def parse_content
    content = container.css('.postContent').text.gsub(/\r+/, "\n").strip
    if content.end_with?('(see all)')
      # TODO: Need to hit API to get full message contents
    end
    content
  end

  def parse_posted_by
    container.css('[id$="postedBySpan"]').text.strip
  end

  def parse_posted_at
    container.css('.postedBy').text.match(/\((.*)\)/)[1]
  end

  def parse_rating
    container.css('[id$="starRating"] img[src$="SolidSmall.png"]').count
  end

  def as_json(options={})
    {
      content: parse_content,
      posted_by: parse_posted_by,
      posted_at: parse_posted_at,
      rating: parse_rating
    }
  end
end
