# encoding: UTF-8
require_relative '../script_util.rb'

FILE_PATH = File.expand_path('../../../data/mgci/sets.json', __FILE__)
def key(set_json); set_json['mgci_code']; end

def extract_data(link)
  href = link.attributes['href'].value
  {
    'name' => link.text,
    'mgci_code' => href.split('/')[1]
  }
end

def merge(data)
  existing = Hash[read(FILE_PATH).map{|s| [key(s), s]}]
  data.each do |set|
    existing[key(set)] = (existing[key(set)] || {}).merge(set)
  end
  existing.values
end

page = get 'http://magiccards.info/sitemap.html'
links = page.css('li a[href$="en.html"]')
write FILE_PATH, merge(
        links.map(&method(:extract_data))
      ).sort_by{|set| set['name']}
