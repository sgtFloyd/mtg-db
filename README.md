mtg-db [![Gem Version](https://badge.fury.io/rb/mtg-db.svg)](
  https://rubygems.org/gems/mtg-db)
======
A JSON database of _Magic: The Gathering_ cards.

# Installation
Include in your [Gemfile]
```ruby
source 'https://rubygems.org'
gem 'mtg-db', '>= 1.4.1'
```
or install from [Rubygems]
```bash
gem install mtg-db
```

[Gemfile]: https://bundler.io/gemfile.html
[Rubygems]: https://rubygems.org/

# Usage
## Ruby
```ruby
require 'mtg-db'

all_sets = Mtg::Db.sets
all_set_json = Mtg::Db.sets.to_json

all_cards = Mtg::Db.cards
all_card_json = Mtg::Db.cards.to_json

aether_revolt_cards = Mtg::Db.cards(:aer)
```

# JSON Format

## Sets
A **set** in _Magic: The Gathering_ is a pool of cards released together and designed for the same play environment.<sup>[1]</sup>

[1]: https://mtg.gamepedia.com/Set

###### ATTRIBUTES
- **name**: Required string. The set's name as listed on Wizards of the Coasts's **[Gatherer]** card database, with some exceptions made for consistency. See [set_name_overrides.yml](script/data/set_name_overrides.yml)
- **release_date**: Required string. The calendar date of the set's release. In the case of some older sets, the closest known date is used.
-  ~**block**~: _Deprecated._ Optional string. A group of sequential expansion<sup>[2]</sup> sets with shared mechanics or flavor. Also used to group supplemental<sup>[3]</sup> sets by product line.
- **code**: Required string. The unique code used to identify the set. By default the expansion code from **[Gatherer]** is used, with exceptions defined in [set_code_overrides.yml](script/data/set_code_overrides.yml). Often a three-character string. Notable exceptions are Masterpiece sets, Duel Decks and Guild Kits with codes `mps_kld`, `dd3_dvd`, `gk1_golgari` etc.

[Gatherer]: http://gatherer.wizards.com/Pages/Default.aspx
[URZA.co]: https://urza.co/m
[2]: https://mtg.gamepedia.com/Set#Expansions
[3]: https://mtg.gamepedia.com/Set#Supplemental_sets

###### EXAMPLE JSON
```json
{
  "name": "Aether Revolt",
  "release_date": "January 20, 2017",
  "block": "Kaladesh Block",
  "code": "aer"
}
```

## Cards

###### ATTRIBUTES
- **name**: Required string. The cards's name as listed on Wizards of the Coasts's **[Gatherer]** card database.
- **set_name**: Required string. The _Magic_ set this card is from. Multiple sets may contain the same card though `collector_num`, `rarity`, `illustrator`, `flavor_text` and `multiverse_id` will differ between printings.
- **collector_num**: Required string. This card's collector number. First used in _Exous_, collector numbers for earlier sets have been generated using the same ordering system. May contain letters or numbers.
- **illustrator**: Optional string.
- **types**: Required string array.
  - _Artifact, Conspiracy, Creature, Enchantment, Instant, Land, Planeswalker, Sorcery, Tribal_
- **supertypes**: Optional string array.
  -  _Basic, Legendary, World, Snow_
- **subtypes**: Optional string array.
- **rarity**: Required string.
  - _Common, Uncommon, Rare, Mythic, Special, Land_
- **mana_cost**: Optional string.
- **converted_mana_cost**: Required integer.
- **oracle_text**: Optional string array.
- **flavor_text**: Optional string.
- **power**: Optional string.
  - Only applies to cards with the _Vehicle_ or _Creature_ type.
- **toughness**: Optional string.
  - Only applies to cards with the _Vehicle_ or _Creature_ type.
- **loyalty**: Optional string.
  - Only applies to cards with the _Planeswalker_ type.
- **multiverse_id**: Optional integer.
- **other_part**: Optional string.
- **color_indicator**: Optional string. Used when a card's color can't be identified by its mana cost.
  - _White, Blue, Black, Red, Green_

[Gatherer]: http://gatherer.wizards.com/Pages/Default.aspx

###### EXAMPLE JSON
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
