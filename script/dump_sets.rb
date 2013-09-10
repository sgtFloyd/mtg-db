require 'multi_json'
require 'nokogiri'
require 'open-uri'

FILE_PATH = File.expand_path('../../data/sets.json', __FILE__)

def get(url); Nokogiri::HTML( open(url) ); end

def extract_data(link)
  href = link.attributes['href'].value
  {
    'name' => link.text,
    'mgci_code' => href.split('/')[1]
  }
end

def merge(data)
  existing = Hash[read.map{|s| [s['mgci_code'], s]}]
  data.each do |set|
    existing[set['mgci_code']] = (existing[set['mgci_code']] || {}).merge(set)
  end
  existing.values
end

def read
  File.open(FILE_PATH, 'r') do |file|
    return MultiJson.load(file.read)
  end
rescue
  []
end

def write(data)
  File.open(FILE_PATH, 'w') do |file|
    file.puts MultiJson.dump(data, pretty: true)
  end
end

page = get 'http://magiccards.info/sitemap.html'
links = page.css('li a[href$="en.html"]')
write merge(
        links.map(&method(:extract_data))
      ).sort_by{|set| set['name']}
