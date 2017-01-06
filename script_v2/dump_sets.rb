Dir.glob(File.expand_path(File.join('..', 'util', '*.rb'), __FILE__), &method(:require))
require_relative './scrapers/gatherer_set_scraper.rb'

set_json = GathererSetScraper.run
write SET_JSON_FILE_PATH, set_json
