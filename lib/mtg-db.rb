require 'json'

module Mtg
  module Db
    VERSION = '1.2.4'
    CARDS_PATH = File.expand_path('../../data/sets/%s.json', __FILE__)
    SETS_PATH = File.expand_path('../../data/sets.json', __FILE__)

    class << self
      def cards(set_code = nil)
        if set_code
          load_json(CARDS_PATH % set_code)
        else
          @cards ||= sets.inject([]) do |cards, set|
            cards + load_json(CARDS_PATH % set['code'])
          end
        end
      end

      def sets
        @sets ||= load_json SETS_PATH
      end

    private

      def load_json(path)
        if File.exists?(path)
          File.open(path, 'r') do |f|
            JSON.parse(f.read)
          end
        else
          []
        end
      end

    end
  end
end
