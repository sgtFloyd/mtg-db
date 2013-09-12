# encoding: UTF-8
require 'fileutils'
require 'multi_json'
require 'open-uri'

def raw_sets
  path = File.expand_path('../../data/sets.json', __FILE__)
  File.open(path, 'r'){|file| MultiJson.load(file.read)}
end
def raw_cards
  path = File.expand_path('../../data/cards.json', __FILE__)
  File.open(path, 'r'){|file| MultiJson.load(file.read)}
end

def sets
  @sets ||= raw_sets.select do |set|
    set['mgci_code'] && set['gatherer_code']
  end
end
def get_set(name)
  (@_sets ||= {})[name] ||= # memoize return value
    sets.find{|s| s['name'] == name}
end

raw_cards.each do |card|
  next unless set = get_set(card['set_name'])
  puts uri = "http://magiccards.info/scans/en/#{set['mgci_code']}/#{card['collector_num']}.jpg"
  FileUtils.mkdir_p dir = File.join('data', 'images', '312x445', set['gatherer_code'])
  File.open(File.join(dir, File.basename(uri)), 'wb'){|f| f.write(open(uri).read)}
end
