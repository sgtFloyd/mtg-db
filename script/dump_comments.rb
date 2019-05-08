Dir.glob(File.expand_path(File.join('..', 'util', '*.rb'), __FILE__), &method(:require))
require File.expand_path(File.join('..', 'gatherer', 'util.rb'), __FILE__)
require File.expand_path(File.join('..', 'gatherer', 'comment.rb'), __FILE__)
require File.expand_path(File.join('..', 'gatherer', 'comment_page.rb'), __FILE__)

(puts "usage: rake comments set_code [...]"; exit(0)) if ARGV.none?
ALL_SETS = read(SET_JSON_FILE_PATH)
SETS_TO_DUMP = ALL_SETS.select{|s| s['code'].in? ARGV}

SETS_TO_DUMP.each do |set|
  set_json_path = "#{CARD_JSON_FILE_PATH}/#{set['code']}.json"
  set_json = read(set_json_path)

  comment_json = {}
  multiverse_ids = set_json.map{|card| card['multiverse_id']}.compact.first(3)
  Worker.distribute(multiverse_ids, GathererCommentPage, :dump).each{|id, comments| comment_json[id] = comments} # asynchronous
  # multiverse_ids.map{|id| _,comments = GathererCommentPage.dump(id); comment_json[id] = comments} # synchronous

  next if comment_json.empty?
  comment_json_path = "#{COMMENT_JSON_FILE_PATH}/#{set['code']}.json"
  write(comment_json_path, comment_json)
end
