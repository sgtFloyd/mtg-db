require 'json'

module Mtg
  module Db
    VERSION = '0.7.6'
    CARDS_PATH = File.expand_path('../../data/cards.json', __FILE__)
    SETS_PATH = File.expand_path('../../data/sets.json', __FILE__)
    SET_IMAGES = File.expand_path('../../data/images/**/*.png', __FILE__)

    class << self
      def cards
        @cards ||= load_json CARDS_PATH
      end

      def sets
        @sets ||= load_json SETS_PATH
      end

      def images
        base = Hash.new{|h,k|h[k]={}}
        @images ||=
          Dir[SET_IMAGES].inject(base) do |h, path|
            set = File.basename(File.dirname(path))
            version = File.basename(path, '.png')
            h[set][version.to_sym] = path; h
          end
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
