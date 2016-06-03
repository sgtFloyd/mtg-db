require 'json'

module Mtg
  module Db
    VERSION = '0.8.10'
    CARDS_PATH = File.expand_path('../../data/cards.json', __FILE__)
    SETS_PATH = File.expand_path('../../data/sets.json', __FILE__)

    class << self
      def cards
        @cards ||= load_json CARDS_PATH
      end

      def sets
        @sets ||= load_json SETS_PATH
      end

    private

      def load_json(path)
        File.open(path, 'r') do |f|
          JSON.parse(f.read)
        end
      end

    end
  end
end
