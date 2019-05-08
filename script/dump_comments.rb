Dir.glob(File.expand_path(File.join('..', 'util', '*.rb'), __FILE__), &method(:require))
require File.expand_path(File.join('..', 'gatherer', 'util.rb'), __FILE__)
require File.expand_path(File.join('..', 'gatherer', 'comment.rb'), __FILE__)

(puts "usage: rake comments set_code [...]"; exit(0)) if ARGV.none?
ALL_SETS = read(SET_JSON_FILE_PATH)
SETS_TO_DUMP = ALL_SETS.select{|s| s['code'].in? ARGV}

def scrape_all_comments(multiverse_id)
  comments_page = get Gatherer.url(for_comments: multiverse_id)
  all_comments = []
  loop do
    all_comments += scrape_page(comments_page)
    break unless has_next_page?(comments_page)
    comments_page = get_next_page(comments_page)
  end
  all_comments
end

def scrape_page(comments_page)
  comment_containers = comments_page.css('.postContainer .post:not(.zeroItem)')
  comment_containers.map do |container|
    GathererComment.new(container).as_json
  end
end

def has_next_page?(comments_page)
  # TODO
end

def get_next_page(comments_page)
  # TODO
end

SETS_TO_DUMP.each do |set|
  set_json_path = "#{CARD_JSON_FILE_PATH}/#{set['code']}.json"
  set_json = read(set_json_path)
  set_json.each do |card|
    comments = scrape_all_comments(card['multiverse_id'])
    require 'pry'; binding.pry
  end
end
