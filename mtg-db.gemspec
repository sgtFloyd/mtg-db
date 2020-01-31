require './lib/mtg-db'

Gem::Specification.new do |s|
  s.name    = "mtg-db"
  s.version = Mtg::Db::VERSION
  s.summary = "Ruby gem containing JSON data for all Magic: The Gathering cards."
  s.license = 'MIT'

  s.authors     = ["Gabe Smith"]
  s.email       = ["sgt.floydpepper@gmail.com"]
  s.date        = Time.now.strftime "%Y-%m-%d"
  s.homepage    = "https://github.com/sgtFloyd/mtg-db"
  s.description = "mtg-db is a Ruby gem containing data for all Magic: The Gathering cards and sets, in JSON format. The linked repository contains rake scripts to scrape new data and update the JSON files."

  s.require_paths = ["lib"]
  s.files         = Dir['lib/**/*.rb'] +
                    Dir['data/**/*.json']
end
