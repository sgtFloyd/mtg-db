class GathererComment
  attr_accessor :container
  def initialize(container)
    self.container = container
  end

  # Request Headers:
  # POST /Handlers/RPCUtilities.ashx HTTP/1.1
  # Host: gatherer.wizards.com
  # Connection: keep-alive
  # Content-Length: 37
  # Accept: text/javascript, text/html, application/xml, text/xml, */*
  # X-Prototype-Version: 1.6.1
  # Origin: https://gatherer.wizards.com
  # X-Requested-With: XMLHttpRequest
  # User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.131 Safari/537.36
  # Content-type: application/x-www-form-urlencoded; charset=UTF-8
  # Referer: https://gatherer.wizards.com/Pages/Card/Discussion.aspx?multiverseid=191239
  # Accept-Encoding: gzip, deflate, br
  # Accept-Language: en-US,en;q=0.9,la;q=0.8
  # Cookie: CardDatabaseSettings=1=en-US; BIGipServergatherer.wizards.com=539232266.20480.0000; ASP.NET_SessionId=
  COMMENT_API_URL = 'https://gatherer.wizards.com/Handlers/RPCUtilities.ashx'
  def self.fetch_comment_api(post_id)
    form_data = {'_' => ' ', 'method' => 'GetCardComment', 'postID' => post_id}
    response = post_form(COMMENT_API_URL, form_data)
  end

  def parse_content
    content = container.css('.postContent').text.gsub(/\r+/, "\n").strip

    # Hit API to retrieve full post content if (see all) link is preent.
    if content.end_with?('(see all)')
      see_all_link = container.css('a[onclick^="ExpandPost"]')
      post_id = see_all_link.attribute('onclick').value.match(/(\d+)\)/)[1]
      comment_json = self.class.fetch_comment_api(post_id)
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
