Dir.glob(File.expand_path(File.join('..', 'util', '*.rb'), __FILE__), &method(:require))
require_relative './gatherer/gatherer_set.rb'

set_json = GathererSet.run
write SET_JSON_FILE_PATH, set_json
