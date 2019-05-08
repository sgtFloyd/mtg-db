class GathererCommentPage
  attr_accessor :multiverse_id

  def initialize(multiverse_id)
    self.multiverse_id = multiverse_id
  end

  def self.dump(multiverse_id)
    [
      multiverse_id,
      self.new(multiverse_id).scrape_all_comments
    ]
  end

  def scrape_all_comments
    all_comments = []
    next_page = 0

    loop do # step through all pages
      comments_page = get Gatherer.url(for_comments: self.multiverse_id, page: next_page)
      all_comments += scrape_page(comments_page)
      next_page = next_page_num(comments_page)
      break unless next_page
    end
    all_comments
  end

  def scrape_page(comments_page)
    comment_containers = comments_page.css('.postContainer .post:not(.zeroItem)')
    comment_containers.map do |container|
      GathererComment.new(container).as_json
    end
  end

  def next_page_num(comments_page)
    return unless comments_page.css('.pagingControls a').present? # has_pagination?
    current_page_num = comments_page.css('.pagingControls a[style="text-decoration:underline;"]').text.to_i
    has_next_page = comments_page.css('.pagingControls a').any? do |link|
      link.text.to_i == current_page_num + 1
    end
    return current_page_num if has_next_page
  end
end
