mtg-db [![Gem Version](https://badge.fury.io/rb/mtg-db.svg)](
  https://rubygems.org/gems/mtg-db)
======
A JSON database of _Magic: The Gathering_ cards.

# Installation
Include in your [Gemfile]
```ruby
source 'https://rubygems.org'
gem 'mtg-db', '>= 2.3.6'
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
- **name** Required string. The set's name as listed on Wizards of the Coasts's **[Gatherer]** card database.
- **release_date** Required string. The calendar date of the set's release. In the case of some older sets, the closest known date is used.
- **code** Required string. The unique code used to identify the set. Often a three-character string. Notable exceptions are Masterpiece sets and Duel Decks with codes `mps_kld`, `dd3_dvd`, etc.

[Gatherer]: http://gatherer.wizards.com/Pages/Default.aspx

###### EXAMPLE JSON
```json
{
  "name": "Aether Revolt",
  "release_date": "January 20, 2017",
  "code": "aer"
}
```

###### EXCEPTIONS
**mtg-db** overrides the attributes of some sets to maintain internal consistency and correct Gatherer errors. See these override files:
- [excluded_sets.yml](script/data/excluded_sets.yml)
- [set_code_overrides.yml](script/data/set_code_overrides.yml)
- [set_name_overrides.yml](script/data/set_name_overrides.yml)

## Cards

###### ATTRIBUTES
- **name** Required string. The cards's name as listed on Wizards of the Coasts's **[Gatherer]** card database.
- **set_name** Required string. The _Magic_ set this card is from.
- **collector_num**<sup>[2]</sup> Required string. This card's collector number. First used in _Exous_, collector numbers for earlier sets have been generated using the same ordering system. May contain letters and numbers.
- **illustrator** Optional string. The illustrator of this card's art.
- **types**<sup>[3]</sup> Required string array of the card's types. Possible values are _Artifact, Conspiracy, Creature, Enchantment, Instant, Land, Planeswalker, Sorcery, Tribal,_ and _Vanguard_.
- **supertypes**<sup>[4]</sup> Optional string array of the card's supertypes. Possible values are _Basic, Legendary, World,_ and _Snow_.
- **subtypes**<sup>[5]</sup> Optional string array of the card's subtypes.
- **rarity**<sup>[6]</sup> Required string. Rarity defines the scarcity of cards in boosters and indicates the complexity of the card. Possible values are _Common, Uncommon, Rare, Mythic, Special,_ and _Land_.
- **mana_cost**<sup>[7]</sup> Optional string. The mana payment required to cast a spell. See [mana_cost_symbols.yml](script/data/mana_cost_symbols.yml) for the system used to encode mana symbols.
- **converted_mana_cost** <sup>[8]</sup> Required integer. The total amount of mana the card's mana cost, regardless of color.
- **oracle_text**<sup>[9]</sup> Optional string array of the card's up-to-date rules text. Each element of the array represents one line of rules text. Four times a year the Oracle is updated to incorporate changes to cards that do not work as intended.
- **flavor_text**<sup>[10]</sup> Optional string. Italicized text that serves to provide mood or give background information on the game world, but has no effect on gameplay.
- **power**<sup>[11]</sup> Optional string. The amount of damage a _Creature_ or _Vehicle_ deals. Usually an integer, but may contain a modifier such as _*_ or _X_.
- **toughness**<sup>[12]</sup> Optional string. The amount of damage needed to kill a _Creature_ or _Vehicle_. Usually an integer, but may contain a modifier such as _*_ or _X_.
- **loyalty**<sup>[13]</sup> Optional string. The number of loyalty counters a _Planeswalker_ enters the battlefield with. Usually an integer, but may contain a modifier such as _X_.
- **multiverse_id**: Optional integer. An identifier unique to the printing of a card. Cards missing from [Gatherer] will have an empty multiverse_id.
- **other_part**: Optional string. The name of the other half of a double-faced,<sup>[14]</sup> flip,<sup>[15]</sup> meld,<sup>[16]</sup> or split card.<sup>[17]</sup>
- **color_indicator**<sup>[18]</sup> Optional string. Used when a card's color can't be identified by its mana cost. Possible values are _White, Blue, Black, Red,_ or _Green_
- **rulings** Optional array of objects, each containing the text and date for an Oracle ruling associated with this card.

[Gatherer]: http://gatherer.wizards.com/Pages/Default.aspx
[2]: https://mtg.gamepedia.com/Collector_number
[3]: https://mtg.gamepedia.com/Card_type
[4]: https://mtg.gamepedia.com/Supertype
[5]: https://mtg.gamepedia.com/Subtype
[6]: https://mtg.gamepedia.com/Rarity
[7]: https://mtg.gamepedia.com/Mana_cost
[8]: https://mtg.gamepedia.com/Mana#Converted_mana_cost
[9]: https://mtg.gamepedia.com/Rules_text
[10]: https://mtg.gamepedia.com/Flavor_text
[11]: https://mtg.gamepedia.com/Power_and_toughness#Power
[12]: https://mtg.gamepedia.com/Power_and_toughness#Toughness
[13]: https://mtg.gamepedia.com/Loyalty
[14]: https://mtg.gamepedia.com/Double-faced_card
[15]: https://mtg.gamepedia.com/Flip_card
[16]: https://mtg.gamepedia.com/Meld_card
[17]: https://mtg.gamepedia.com/Split_card
[18]: https://mtg.gamepedia.com/Color_indicator

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
  "color_indicator": null,
  "rulings": [
    {
      "date": "2/9/2017",
      "text": "If Aerial Modification becomes unattached from a Vehicle that’s attacking or blocking, that Vehicle will be removed from combat unless another effect (such as its crew ability) is also making it a creature."
    }
  ]
}
```

###### EXCEPTIONS
**mtg-db** overrides the attributes of some cards to maintain internal consistency and correct Gatherer errors. See these override files:
- [card_json_overrides.yml](script/data/card_json_overrides.yml)
- [card_name_overrides.yml](script/data/card_name_overrides.yml)
- [collector_num_overrides.yml](script/data/collector_num_overrides.yml)
- [excluded_multiverse_ids.yml](script/data/excluded_multiverse_ids.yml)
- [flavor_text_overrides.yml](script/data/flavor_text_overrides.yml)
- [illustrator_overrides.yml](script/data/illustrator_overrides.yml)
- [partner_card_names.yml](script/data/partner_card_names.yml)
- [split_card_names.yml](script/data/split_card_names.yml)
