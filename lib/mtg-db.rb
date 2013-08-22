require 'json'

module Mtg
  module Db
    VERSION = '0.0.1'

    class << self
      def cards(reload=false)
        @cards = nil if reload
        @cards ||= load_json File.expand_path('cards.json', 'data')
      end

      def sets(reload=false)
        @sets = nil if reload
        @sets ||= load_json File.expand_path('sets.json', 'data')
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
