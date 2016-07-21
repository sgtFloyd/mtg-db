require 'celluloid/current'
require 'cgi'
require 'fileutils'
require 'multi_json'
require 'nokogiri'
require 'open-uri'
require 'yaml'

SET_JSON_FILE_PATH =  File.expand_path('../../data_v2/sets.json', __FILE__)
EXCLUDED_SETS =       YAML.load_file(File.expand_path '../data/excluded_sets.yml', __FILE__)
SET_CODE_OVERRIDES =  YAML.load_file(File.expand_path '../data/set_code_overrides.yml', __FILE__)
SET_NAME_OVERRIDES =  YAML.load_file(File.expand_path '../data/set_name_overrides.yml', __FILE__)

class Object
  def try(*a, &b)
    __send__(*a, &b) unless self.nil?
  end
  def in?(enumerable)
    enumerable.include?(self)
  end
end

def get(url)
  puts "getting #{url}"
  Nokogiri::HTML(open(URI.escape url))
rescue => e
  puts "#{e}. Retrying in 500ms ..."; sleep 0.5
  Nokogiri::HTML(open(URI.escape url))
end

def read(path)
  puts "reading #{path}"
  File.open(path, 'r') do |file|
    return MultiJson.load(file.read)
  end
rescue
  puts "#{e}. Failed to read #{path}"
  []
end

def write(path, data)
  puts "writing #{path}"
  File.open(path, 'w') do |file|
    file.puts MultiJson.dump(data, pretty: true).gsub(/\[\s+\]/, '[]')
  end
end
