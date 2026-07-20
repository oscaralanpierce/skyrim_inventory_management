# Non-Canonical In-Game Items

Skyrim Inventory Management uses [canonical models](/docs/canonical_models/README.md) to store information about in-game items and validate user input. Most canonical models have a corresponding non-canonical model. These models are scoped to games (i.e., `belongs_to :playthrough`) and associated to the matching canonical model by a one-to-many relationship.

This documentation covers the scope and purpose of non-canonical in-game items, their associations, and specifics pertaining to particular models that require additional explanation.

## Table of Contents

* [In-Game Items](/docs/in_game_items/in-game-items.md): An overview of in-game item models, which models exist, and associations between them
* Models:
  * [`Armor`](/docs/in_game_items/armor.md)
  * [`Book`](/docs/in_game_items/book.md)
  * [`ClothingItem`](/docs/in_game_items/clothing-item.md)
  * [`Ingredient`](/docs/in_game_items/ingredient.md)
  * [`JewelryItem`](/docs/in_game_items/jewelry-item.md)
  * [`MiscItem`](/docs/in_game_items/misc-item.md)
  * [`Potion`](/docs/in_game_items/potion.md)
  * [`Staff`](/docs/in_game_items/staff.md)
  * [`Weapon`](/docs/in_game_items/weapon.md)
* Join models:
  * [`IngredientsAlchemicalProperty`](/docs/in_game_items/ingredients-alchemical-property.md)
  * `EnchantablesEnchantment` (both canonical and non-canonical use same table)
  * [`PotionsAlchemicalProperty`](/docs/in_game_items/potions-alchemical-property.md)
  * [`RecipesCanonicalIngredient`](/docs/canonical_models/recipes-canonical-ingredient.md)
