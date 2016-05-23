# encoding: UTF-8
$ran_as_script = __FILE__==$0

require_relative './script_util.rb'

class ImageDumper
  def self.raw_sets
    @_raw_sets ||= read(File.expand_path('../../data/sets.json', __FILE__))
  end

  def self.raw_cards
    @_raw_cards ||= read(File.expand_path('../../data/cards.json', __FILE__))
  end

  def initialize(import_set=nil)
    @import_set = Array(import_set)
    @_set_cache = {}
    self.class.raw_cards; self.class.raw_sets # preload json cache
  end

  def read_and_write(uri, set)
    data = open(uri).read
    FileUtils.mkdir_p dir = File.join('data', 'images', 'mgci_312x445', set['mgci_code'])
    File.open(File.join(dir, File.basename(uri)), 'wb'){|f| f.write(data)}
    print '.'
  end

  def run
    print "Dumping images "
    self.class.raw_cards.each do |card|
      next unless set = get_set(card['set_name'])
      uri = "http://magiccards.info/scans/en/#{set['mgci_code']}/#{card['collector_num']}.jpg"
      begin
        read_and_write(uri, set)
      rescue OpenURI::HTTPError => e
        puts "\nFAILED: #{set['mgci_code']}/#{card['collector_num']}.jpg - #{e}"
        puts "Retrying in one second..."; sleep 1; read_and_write(uri, set)
      end
    end
    puts
  end

private

  def sets_to_dump
    @sets ||= self.class.raw_sets.select do |set|
      next if @import_set.any? && !@import_set.include?(set['mgci_code'])
      set['mgci_code']
    end
  end

  def get_set(name)
    @_set_cache[name] ||= sets_to_dump.find{|s| s['name'] == name}
                                      .tap{|s| print "\n#{name} " if s && $ran_as_script}
  end
end

ImageDumper.new(ARGV).run if $ran_as_script
