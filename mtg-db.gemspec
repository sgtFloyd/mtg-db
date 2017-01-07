require './lib/mtg-db'

Gem::Specification.new do |s|
  s.name    = "mtg-db"
  s.version = Mtg::Db::VERSION
  s.summary = "A JSON database of Magic: The Gathering cards and sets."
  s.license = 'MIT'

  s.authors     = ["Gabe Smith"]
  s.email       = ["sgt.floydpepper@gmail.com"]
  s.date        = Time.now.strftime "%Y-%m-%d"
  s.homepage    = "https://github.com/sgtFloyd/mtg-db"
  s.description = "An database of Magic: The Gathering cards and sets in JSON format."

  s.require_paths = ["lib"]
  s.files         = Dir['lib/**/*.rb'] +
                    Dir['data_v2/**/*.json']
end
