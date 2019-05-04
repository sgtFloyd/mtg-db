mtg-db [![Gem Version](https://badge.fury.io/rb/mtg-db.svg)](
  https://rubygems.org/gems/mtg-db)
======
A JSON database of _Magic: The Gathering_ sets and cards.

# Installation
Include in your [Gemfile]
```ruby
source 'https://rubygems.org'
gem 'mtg-db', '>= 1.5.2'
```
or install from [Rubygems]
```bash
gem install mtg-db
```

[Gemfile]: https://bundler.io/gemfile.html
[Rubygems]: https://rubygems.org/

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
A **set** in _Magic: The Gathering_ is a pool of cards released together and designed for the same play environment.<sup>[1]</sup>

[1]: https://mtg.gamepedia.com/Set

#### Attributes
- **`name`**: The set's name as listed on Wizards of the Coasts's **[Gatherer]** card database, with some exceptions made for consistency. See [`set_name_overrides.yml`](script/data/set_name_overrides.yml)
  - Required string. _ex: "Aether Revolt" or "Time Spiral \"Timeshifted\""_
- **`release_date`**: The calendar date of the set's release. In the case of some older sets, the closest known date is used.
  - Required string. _ex: "January 20, 2017" or "October 1993"_
- **`block`**: _Deprecated._ A group of sequential expansion<sup>[2]</sup> sets with shared mechanics or flavor. Also used to group supplemental<sup>[3]</sup> sets by product line.
  - Optional string. _ex: "Kaladesh Block" or "From the Vault Series"_
- **`code`**: The unique code used to identify the set. By default the expansion code from Gatherer is used, with exceptions defined in [`set_code_overrides.yml`](script/data/set_code_overrides.yml)
  - Required string. _ex: "aer" or "10e"_
  - Often a three-character string. Notable exceptions are Masterpiece Series (mps_kld), Duel Decks (dd3_dvd), and Guild Kits (gk1_golgari).

[Gatherer]: http://gatherer.wizards.com/Pages/Default.aspx
[URZA.co]: https://urza.co/m
[2]: https://mtg.gamepedia.com/Set#Expansions
[3]: https://mtg.gamepedia.com/Set#Supplemental_sets

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
