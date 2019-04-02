mtg-db [![Gem Version](https://badge.fury.io/rb/mtg-db.svg)](
  https://rubygems.org/gems/mtg-db)
======
A JSON database of _Magic: The Gathering_ sets and cards.

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

# TODO
all_sets = Mtg::Db.sets

# Returns a JSON array of all Magic: The Gathering sets. See [JSON Format] for details on sets' attributes.
all_set_json = Mtg::Db.sets.to_json

# TODO
all_cards = Mtg::Db.cards

# TODO
all_card_json = Mtg::Db.cards.to_json

# TODO cards are indexed by set code
urzas_destiny_cards = Mtg::Db.cards(:uds).to_json
```

# JSON Format

## Sets
A set in _Magic: The Gathering_ is a pool of cards released together and designed for the same play environment.[1]

#### Attributes
- **`name`**: The set's name as listed on Wizards of the Coasts's **[Gatherer](http://gatherer.wizards.com/Pages/Default.aspx)** card database, with some exceptions made for consistency. See [`set_name_overrides.yml`](script/data/set_name_overrides.yml).
  - Required string. _ex: "Aether Revolt" or "Time Spiral \"Timeshifted\""_
- **`release_date`**: The calendar date of the set's release. In the case of some older sets, the closest known date is used.
  - Required string. _ex: "January 20, 2017" or "October 1993"_
- **`block`**: // TODO Required. SOON TO BE DEPRECATED
  - Optional string. _ex: "Kaladesh Block" or "Core Sets"_
- **`code`**: // TODO
  - Required string. _ex: "aer" or "10e"_

#### Example JSON
```json
{
  "name": "Aether Revolt",
  "release_date": "January 20, 2017",
  "block": "Kaladesh Block",
  "code": "aer"
}
```

## Cards
```json
{
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
}
```

## References
[1]: https://mtg.gamepedia.com/Set
