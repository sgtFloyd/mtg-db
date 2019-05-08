Dir.glob(File.expand_path(File.join('..', 'util', '*.rb'), __FILE__), &method(:require))
require File.expand_path(File.join('..', 'gatherer', 'util.rb'), __FILE__)
require File.expand_path(File.join('..', 'gatherer', 'comment.rb'), __FILE__)

(puts "usage: rake comments set_code [...]"; exit(0)) if ARGV.none?
ALL_SETS = read(SET_JSON_FILE_PATH)
SETS_TO_DUMP = ALL_SETS.select{|s| s['code'].in? ARGV}

def scrape_all_comments(multiverse_id)
  all_comments = []
  next_page = 0

  loop do # step through all pages
    comments_page = get Gatherer.url(for_comments: multiverse_id, page: next_page)
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

SETS_TO_DUMP.each do |set|
  set_json_path = "#{CARD_JSON_FILE_PATH}/#{set['code']}.json"
  set_json = read(set_json_path)

  comment_json = {}
  set_json.each do |card|
    next unless multiverse_id = card['multiverse_id']
    comment_json[multiverse_id] = scrape_all_comments(multiverse_id)
  end

  next if comment_json.empty?
  comment_json_path = "#{COMMENT_JSON_FILE_PATH}/#{set['code']}.json"
  write(comment_json_path, comment_json)
end
