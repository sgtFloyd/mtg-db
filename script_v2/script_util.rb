require 'celluloid/current'
require 'cgi'
require 'fileutils'
require 'multi_json'
require 'nokogiri'
require 'open-uri'
require 'pp'
require 'yaml'

SET_JSON_FILE_PATH =    File.expand_path('../../data_v2/sets.json', __FILE__)
CARD_JSON_FILE_PATH =   File.expand_path('../../data_v2/sets', __FILE__)
FLAVOR_TEXT_FILE_PATH = File.expand_path('../data/flavor_text_overrides.yml', __FILE__)

CARD_JSON_OVERRIDES = YAML.load_file(File.expand_path '../data/card_json_overrides.yml', __FILE__)
FLAVOR_TEXT_OVERRIDES = YAML.load_file(FLAVOR_TEXT_FILE_PATH)
SET_CODE_OVERRIDES =  YAML.load_file(File.expand_path '../data/set_code_overrides.yml', __FILE__)
SET_NAME_OVERRIDES =  YAML.load_file(File.expand_path '../data/set_name_overrides.yml', __FILE__)
COLLECTOR_NUM_OVERRIDES = YAML.load_file(File.expand_path '../data/collector_num_overrides.yml', __FILE__)
ILLUSTRATOR_OVERRIDES = YAML.load_file(File.expand_path '../data/illustrator_overrides.yml', __FILE__)
SPLIT_CARD_NAMES = YAML.load_file(File.expand_path '../data/split_card_names.yml', __FILE__)

MANA_COST_SYMBOLS =   YAML.load_file(File.expand_path '../data/mana_cost_symbols.yml', __FILE__)
EXCLUDED_SETS =       YAML.load_file(File.expand_path '../data/excluded_sets.yml', __FILE__)
EXCLUDED_MULTIVERSE_IDS = YAML.load_file(File.expand_path '../data/excluded_multiverse_ids.yml', __FILE__)
EXCLUDED_TOKEN_NAMES = ['Goblin', 'Soldier', 'Kraken', 'Spirit']
BASIC_LAND_SYMBOL = {'Plains'   => '{W}', 'Island' => '{U}', 'Swamp'  => '{B}',
                     'Mountain' => '{R}', 'Forest' => '{G}', 'Wastes' => '{C}'}

class Object
  def try(*a, &b)
    __send__(*a, &b) unless self.nil?
  end
  def in?(enumerable)
    enumerable.include?(self)
  end
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end
  def present?
    !blank?
  end
  def presence
    self if present?
  end
  def exclude?(obj)
    !include?(obj)
  end
end

def get(url, headers={})
  puts "getting #{url}"
  Nokogiri::HTML( open(URI.escape(url), headers) )
rescue => e
  puts "#{e}. Retrying in 500ms ..."; sleep 0.5
  Nokogiri::HTML( open(URI.escape(url), headers) )
end

def read(path, parser: MultiJson, silent: false)
  puts "reading #{path}" unless silent
  File.open(path, 'r') do |file|
    return parser.load(file.read)
  end
rescue => e
  puts "#{e}. Failed to read #{path}"
  []
end

def write(path, data, silent: false)
  puts "writing #{path}" unless silent
  File.open(path, 'w') do |file|
    file.puts MultiJson.dump(data, pretty: true).gsub(/\[\s+\]/, '[]')
  end
end

module Decorator
  def decorate_method(fn, &block)
    fxn = instance_method(fn)
    define_method fn do |*args|
      instance_exec(fxn.bind(self), *args, &block)
    end
  rescue NameError, NoMethodError
    fxn = singleton_class.instance_method(fn).bind(self)
    define_singleton_method fn do |*args|
      instance_exec(fxn, *args, &block)
    end
  end
end

module Memoizer
  include Decorator

  def memoize(fn, cache: Hash.new{|h,k|h[k]={}})
    decorate_method(fn) do |meth, *args|
      unless cache[self].include?(args)
        cache[self][args] = meth.call(*args)
      end
      cache[self][args]
    end
  end
  alias :memo :memoize
end
