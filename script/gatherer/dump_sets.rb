require_relative '../script_util.rb'

FILE_PATH = File.expand_path('../../../data/gatherer/sets.json', __FILE__)

def extract_data(item)
  name = item.text
  return unless substitute(name)
  return unless code = set_code(name)
  name = substitute(name)
  {
    'name' => name,
    'gatherer_code' => code
  }
end

# Visit search page in order to get the set code. Not ideal.
def set_code(name)
  set_url = "http://gatherer.wizards.com/Pages/Search/Default.aspx?set=[\"#{name}\"]"
  img = get(set_url).css("img").find{|i| i.attr(:title).try(:match, name)}
  CGI.parse(img.attr(:src))['set'].first.try(:downcase) if img
end

def substitute(name)
  case name
  when "Magic: The Gathering-Commander"
    "Commander"
  when "Promo set for Gatherer"
    nil
  else name
  end
end

page = get('http://gatherer.wizards.com/Pages/Default.aspx')
list = page.css('#ctl00_ctl00_MainContent_Content_SearchControls_setAddText option')
write FILE_PATH, list.map(&method(:extract_data)).compact
