# encoding: UTF-8
require 'fileutils'
require 'multi_json'
require 'open-uri'

def sets
  path = File.expand_path('../../data/sets.json', __FILE__)
  File.open(path, 'r') do |file|; return MultiJson.load(file.read); end
end

def mgci_sets
  @mgci_sets ||= sets.select{|s| s['mgci_code']}
end

def mgci_code(name)
  (@mgci_codes ||= {})[name] ||= # memoize return value
    mgci_sets.find{|s| s['name'] == name}['mgci_code'] rescue nil
end

def cards
  path = File.expand_path('../../data/cards.json', __FILE__)
  File.open(path, 'r') do |file|; return MultiJson.load(file.read); end
end

cards.each do |card|
  next unless set_code = mgci_code(card['set_name'])
  puts uri = "http://magiccards.info/scans/en/#{set_code}/#{card['collector_num']}.jpg"
  FileUtils.mkdir_p dir = File.join('data', 'images', '312x445', set_code)
  File.open(File.join(dir, File.basename(uri)), 'wb'){|f| f.write(open(uri).read)}
end
