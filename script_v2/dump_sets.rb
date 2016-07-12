require_relative './script_util.rb'

FILE_PATH = File.expand_path('../../data_v2/sets.json', __FILE__)

page = get "http://gatherer.wizards.com/Pages/Default.aspx"
sets = page.css('select[name$="setAddText"] option').map(&:text).reject(&:empty?)
sets.each do |set|
  set_page = get "http://gatherer.wizards.com/Pages/Search/Default.aspx?set=[%22#{set}%22]"
  require 'pry'; binding.pry
end
