mtg-db
======
A JSON database of _Magic: The Gathering_ cards and sets.

[![Gem Version](https://badge.fury.io/rb/mtg-db.svg)](https://rubygems.org/gems/mtg-db)

# Installation
Include in your [Gemfile](https://bundler.io/gemfile.html)
```ruby
source 'https://rubygems.org'
gem 'mtg-db', '>= 1.4.1'
```
or install from [Rubygems](https://rubygems.org/)
```bash
gem install mtg-db
```

# Usage
Ruby:
```ruby
require 'mtg-db'
all_sets = Mtg::Db.sets.to_json
<<-JSON
[{
  "name": "Aether Revolt",
  "release_date": "January 20, 2017",
  "block": "Kaladesh Block",
  "code": "aer"
},
{
  "name": "Alara Reborn",
  "release_date": "April 30, 2009",
  "block": "Alara Block",
  "code": "arb"
},
{
  "name": "Alliances",
  "release_date": "June 10, 1996",
  "block": "Ice Age Block",
  "code": "all"
},
...
JSON

all_cards = Mtg::Db.cards.to_json
<<-JSON
[{
  "name": "Aerial Modification",
  "set_name": "Aether Revolt",
  "collector_num": "1",
  "illustrator": "Jung Park",
  "types": [
    "Enchantment"
  ],
  "supertypes": [],
  "subtypes": [
    "Aura"
  ],
  "rarity": "Uncommon",
  "mana_cost": "4W",
  "converted_mana_cost": 5,
  "oracle_text": [
    "Enchant creature or Vehicle",
    "As long as enchanted permanent is a Vehicle, it's a creature in addition to its other types.",
    "Enchanted creature gets +2/+2 and has flying."
  ],
  "flavor_text": null,
  "power": null,
  "toughness": null,
  "loyalty": null,
  "multiverse_id": 423668,
  "other_part": null,
  "color_indicator": null
},
{
  "name": "Aeronaut Admiral",
  "set_name": "Aether Revolt",
  "collector_num": "2",
  ...
JSON

# cards are indexed by set code
urzas_destiny_cards = Mtg::Db.cards(:uds).to_json
<<-JSON
[{
  "name": "Academy Rector",
  "set_name": "Urza's Destiny",
  "collector_num": "1",
  "illustrator": "Heather Hudson",
  "types": [
    "Creature"
  ],
  "supertypes": [],
  "subtypes": [
    "Human",
    "Cleric"
  ],
  "rarity": "Rare",
  "mana_cost": "3W",
  "converted_mana_cost": 4,
  "oracle_text": [
    "When Academy Rector dies, you may exile it. If you do, search your library for an enchantment card, put that card onto the battlefield, then shuffle your library."
  ],
  "flavor_text": null,
  "power": "1",
  "toughness": "2",
  "loyalty": null,
  "multiverse_id": 15138,
  "other_part": null,
  "color_indicator": null
},
{
  "name": "Archery Training",
  "set_name": "Urza's Destiny",
  "collector_num": "2",
  ...
JSON
```
