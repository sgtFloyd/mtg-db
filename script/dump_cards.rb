# encoding: UTF-8
require 'multi_json'
require 'nokogiri'
require 'open-uri'

FILE_PATH = File.expand_path('../../data/cards.json', __FILE__)
def get(url); puts "getting #{url}"; Nokogiri::HTML(open(url)); end

def key(card_json); [card_json['set_name'], card_json['collector_num']]; end

def merge(data)
  existing = Hash[read.map{|c| [key(c), c]}]
  data.each do |card|
    existing[key(card)] = (existing[key(card)] || {}).merge(card)
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
    file.puts pretty_generate(data)
  end
end

def pretty_generate(json)
  MultiJson.dump(json, pretty: true).gsub(/\[\s+\]/, '[]')
end

def sets
  path = File.expand_path('../../data/sets.json', __FILE__)
  File.open(path, 'r') do |file|
    return MultiJson.load(file.read)
  end
end

def extract_cnums(set_code)
  spoiler = get "http://magiccards.info/#{ set_code }/en.html"
  links = spoiler.css("td a[href*=\"/#{ set_code }/en/\"]")
  links.map{|link|
    href = link.attributes['href'].value
    href.split(/[\.\/]/)[-2]
  }
end

class CardPage
  def initialize(set, num)
    @set_name = set['name']
    @set_code = set['mgci_code']
    @collector_num = num
  end

  def mana_cost
    @_center_p_first ||= center_div.css('p:first').first.text rescue nil
    @mana_cost ||= @_center_p_first.to_s.split("\n").map{|s| s.strip.chomp(',')}[1].strip rescue nil

    if @mana_cost.empty?
      @converted_mana_cost ||= 0
      return nil
    elsif match = @mana_cost.match(/\((.+)\)/)
      @converted_mana_cost ||= match[1].to_i
      cost = @mana_cost.gsub(/\((.+)\)/, '').strip
      return cost.empty? ? nil : cost
    else
      @converted_mana_cost ||= 0
      return @mana_cost
    end
  end
  def cmc
    mana_cost; @converted_mana_cost
  end
  def multiverse_id
    @multiverse_id ||= center_div.css('a[href*="multiverseid"]').first.attr('href').split('=').last
    @multiverse_id == '0' ? nil : @multiverse_id.to_i
  end
  def name
    @name ||= center_div.css("a[href=\"/#{@set_code}/en/#{@collector_num}.html\"]").first.text
  end
  def power
    @power ||= p_t_str ? p_t_str.split('/')[0] : nil
  end
  def toughness
    @toughness ||= p_t_str ? p_t_str.split('/')[1] : nil
  end
  def loyalty
    type_str; @loyalty
  end
  def types
    @_super_and_types ||= type_str.split("—").map(&:strip)[0].split(' ')
    @types ||= @_super_and_types - SUPERTYPES
  end
  def subtypes
    @subtypes ||= type_str.split("—").map(&:strip)[1].split(' ') rescue nil
    @subtypes ||= []
  end
  SUPERTYPES = %w[Basic Legendary World Snow]
  def supertypes
    @_super_and_types ||= type_str.split("—").map(&:strip)[0].split(' ')
    @supertypes ||= (@_super_and_types & SUPERTYPES) || []
  end
  def oracle_text
    @_ctext ||= center_div.css('.ctext')
    @_ctext.css('br').each{|node| node.replace("\n")}
    @oracle_text ||= (@_ctext.text || "").strip.split("\n\n")
    @oracle_text.empty? ? [] : @oracle_text
  end
  def flavor_text
    @flavor_text ||= center_div.css('p')[-3].text
    @flavor_text.empty? ? nil : @flavor_text
  end
  def illustrator
    @illustrator ||= center_div.css('p')[-2].text.gsub(/^Illus. /, '')
    @illustrator.empty? ? nil : @illustrator
  end
  def other_part
    right_div.css('u:contains("The other part is") ~ a').first.text rescue nil
  end
  def color_ind
    @_center_p_first ||= center_div.css('p:first').text rescue nil
    if match = @_center_p_first.match(/\(Color Indicator: (.*)\)/)
      return match[1]
    end
    nil
  end
  def rarity
    @_set_rarity ||= page.css('u:contains("Editions:") ~ b').first.text
    @rarity ||= @_set_rarity.match(/\((.+)\)/)[1]
  end

  def type_str
    @_center_p_first ||= center_div.css('p:first').text rescue nil
    @_type_p_t ||= @_center_p_first.to_s.split("\n").map{|s| s.strip.chomp(',')}[0]
    @_type_str ||= @_type_p_t.split(' ').last.match('/') ? @_type_p_t.split(' ')[0..-2].join(' ') : @_type_p_t
    if matches = @_type_str.match(/\(Loyalty: (.+)\)/)
      @loyalty ||= matches[1]
      @_type_str = @_type_str.gsub(matches[0], '').strip
    end
    @_type_str
  end
  def p_t_str
    @_center_p_first ||= center_div.css('p:first').text rescue nil
    @_type_p_t ||= @_center_p_first.to_s.split("\n").map{|s| s.strip.chomp(',')}[0]
    @_type_p_t.split(' ').last.match('/') ? @_type_p_t.split(' ')[-1] : nil
  end

  def as_json
    {
      'name' => name,                     # Shouldn't be nil
      'set_name' => @set_name,            # Shouldn't be nil
      'collector_num' => @collector_num,  # Shouldn't be nil
      'illustrator' => illustrator,       # Shouldn't be nil
      'types' => types,                   # Can't be nil. Can't be empty []
      'supertypes' => supertypes,         # Can't be nil. Can be empty []
      'subtypes' => subtypes,             # Can't be nil. Can be empty []
      'rarity' => rarity,                 # Can't be nil.
      'mana_cost' => mana_cost,           # Can be nil
      'converted_mana_cost' => cmc,       # Can't be nil. Can be 0
      'oracle_text' => oracle_text,       # Can't be nil. Can be empty []
      'flavor_text' => flavor_text,       # Can be nil
      'power' => power,                   # Can be nil
      'toughness' => toughness,           # Can be nil
      'loyalty' => loyalty,               # Can be nil
      'multiverse_id' => multiverse_id,   # Can be nil. Shouldn't be "0"
      'other_part' => other_part,         # Can be nil. Should be "Name of Card"
      'color_indicator' => color_ind      # Can be nil
    }
  end

private

  def page
    @_page ||= get "http://magiccards.info/#{@set_code}/en/#{@collector_num}.html"
  end

  def center_div
    @_center_div ||= page.css('td[valign="top"][width="70%"]').first
  end

  def right_div
    @_right_div ||= page.css('small').first
  end

end

cards = []
sets.each do |set|
  next if ARGV[0] && ARGV[0] != set['mgci_code']
  cnums = extract_cnums( set['mgci_code'] )
  cards << cnums.map{|n| CardPage.new(set, n).as_json}
end
write merge(cards.flatten)
