Dir.glob(File.expand_path(File.join('..', 'util', '*.rb'), __FILE__), &method(:require))
require_relative './gatherer/set.rb'

set_json = GathererSet.as_json
write SET_JSON_FILE_PATH, set_json
