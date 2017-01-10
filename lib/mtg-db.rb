require 'json'

module Mtg
  module Db
    VERSION = '1.0.6'
    CARDS_PATH = File.expand_path('../../data_v2/sets/%s.json', __FILE__)
    SETS_PATH = File.expand_path('../../data_v2/sets.json', __FILE__)

    class << self
      def cards
        @cards ||= sets.inject([]) do |cards, set|
          cards + load_json(CARDS_PATH % set['code'])
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
