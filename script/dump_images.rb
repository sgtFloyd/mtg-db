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
  @sets ||= raw_sets.select{|set| set['mgci_code']}
end
def get_set(name)
  (@_sets ||= {})[name] ||= ( # memoize return value
    puts name unless @_sets[name];
    sets.find{|s| s['name'] == name}
  )
end

raw_cards.each do |card|
  next unless set = get_set(card['set_name'])
  next if ARGV[0] && ARGV[0] != set['mgci_code']
  puts uri = "http://magiccards.info/scans/en/#{set['mgci_code']}/#{card['collector_num']}.jpg"
  begin; data = open(uri).read
    FileUtils.mkdir_p dir = File.join('data', 'images', 'mgci (312x445)', set['mgci_code'])
    File.open(File.join(dir, File.basename(uri)), 'wb'){|f| f.write(data)}
  rescue OpenURI::HTTPError => e
    puts "FAILED: #{set['mgci_code']}/#{card['collector_num']}.jpg - #{e}"
  end
end
