class GathererComment
  attr_accessor :container
  def initialize(container)
    self.container = container
  end

  COMMENT_API_URL = 'https://gatherer.wizards.com/Handlers/RPCUtilities.ashx'
  COMMENT_API_HEADER = {'Referer' => "https://gatherer.wizards.com/Pages/Card/Discussion.aspx"}
  def self.fetch_api_comment(post_id)
    form_data = {'method' => 'GetCardComment', 'postID' => post_id}
    response = post_form(COMMENT_API_URL, form_data, COMMENT_API_HEADER)
  end

  def parse_content
    content = container.css('.postContent').text.gsub(/[\r\n]+/, "\n").strip
    # Hit API to retrieve full post content if (see all) link is present.
    if content.end_with?('(see all)')
      see_all_link = container.css('a[onclick^="ExpandPost"]')
      post_id = see_all_link.attribute('onclick').value.match(/(\d+)\)/)[1]
      comment_json = self.class.fetch_api_comment(post_id)
      content = comment_json['Data']['PostText'].gsub(/[\r\n]+/, "\n").strip
    end
    require 'pry'; binding.pry
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
