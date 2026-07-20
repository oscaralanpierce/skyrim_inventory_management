# Aggregate Lists

## Contents

* [Overview](#overview)
* [Glossary](#glossary)
* [Database and ORM Requirements](#database-and-orm-requirements)
* [Aggregate List Behaviour](#aggregate-list-behaviour)
  * [Creation and Destruction of Aggregate Lists](#creation-and-destruction-of-aggregate-lists)
  * [Updating Aggregate Lists](#updating-aggregate-lists)
    * [Adding an Item to a Child List](#adding-an-item-to-a-child-list)
    * [Removing an Item from a Child List](#removing-an-item-from-a-child-list)
    * [Editing an Item on a Child List](#editing-an-item-on-a-child-list)
* [List Model Requirements](#list-model-requirements)
* [List Item Model Requirements](#list-item-model-requirements)
* [Aggregatable](#aggregatable)
  * [Associations](#associations)
  * [Scopes](#scopes)
  * [Validations](#validations)
  * [Hooks](#hooks)
  * [Methods](#methods)
  * [What's Automatic and What's Not](#whats-automatic-and-whats-not)
* [Listable](#listable)
  * [Associations](#associations-1)
  * [Scopes](#scopes-1)
  * [Validations](#validations-1)
  * [Hooks](#hooks-1)
  * [Methods](#methods-1)

## Overview

Skyrim Inventory Management makes use of a concept called "aggregate lists". A model that represents a list of other models (e.g., `WishList`, which is a list of `WishListItem` models) can include the `Aggregatable` concern to incorporate aggregate list behaviour. Currently, the only such classes are `WishList` and `InventoryList`. List item models can include the `Listable` concern.

An aggregate list is a list that tracks and aggregates data from other lists (the child lists). When an item is added, removed, or modified on a child list, the corresponding item is added, removed, or modified on the aggregate list as well.

Above where you include `Aggregatable` in the model code, you will need to define a class method called `self.list_item_class_name` that is the class name, as a string, of the class the list items for this type of list belong to:

```ruby
class WishList < ApplicationRecord
  def self.list_item_class_name
    'WishListItem'
  end

  include Aggregatable
end
```
Above where you include the `Listable` module, you will need to define two class methods, `self.list_class` and `self.list_table_name`, to associate the item with its parent list.

```ruby
class InventoryItem < ApplicationRecord
  def self.list_class
    InventoryList
  end

  def self.list_table_name
    'inventory_lists'
  end

  include Listable
end
```

## Glossary

* **Aggregate List:** A list that tracks and aggregates data from a collection of regular lists of the same class. An aggregate list is differentiated from a regular list by its `aggregate` attribute, which is set to `true`. A user can have only one aggregate list for each list class.
* **Regular List:** Any list that is not an aggregate list.
* **Child List:** A regular list belonging to a particular aggregate list.
* **Should/Must:** Used in this document to describe things you will need to implement for models that include aggregate list behaviour.
* **Is/Does/Will:** Used in this document to describe behaviour provided out of the box by the `Aggregatable` and `Listable` concerns.

## Database and ORM Requirements

The database schema for all models that include the `Aggregatable` concern must meet certain requirements:

| Column Name         | Type    | Constraints | Default |
| ------------------- | ------- | ----------- | ------- |
| `aggregate`         | boolean | NOT NULL    | false   |
| `aggregate_list_id` | integer |             |         |
| `playthrough_id`           | integer | NOT NULL    |         |
| `title`             | string  | NOT NULL    |         |

The title for all aggregate lists is "All Items". The titles for other lists may be validated or set to a default value by the individual model if desired. Other than the title, these values should not be changed after initial creation.

You do not need to define any relations in your parent class, and defining a relation to list items may interfere with `Aggregatable`'s functionality.

The database schema for all child models (i.e., the list items for a given list type, which include the `Listable` concern) must also meet certain requirements:

| Column Name   | Type    | Constraints      | Default |
| ------------- | ------- | ---------------- | ------- |
| `list_id`     | integer | NOT NULL         |         |
| `description` | string  | NOT NULL, UNIQUE |         |
| `quantity`    | integer | NOT NULL, > 0    | 1       |
| `unit_weight` | decimal | >= 0             |         |
| `notes`       | string  |                  |         |

**The list item's description should be case insensitive, unique per list and not editable.** List items are uniquely identified on the aggregate list by their descriptions. The `Listable` concern includes a validation to make sure that descriptions cannot be changed.

Note that list items will be destroyed with their parent list.

## Aggregate List Behaviour

Aggregate list behaviour is complex and involves both list items and the lists themselves.

### Creation and Destruction of Aggregate Lists

Best practice for aggregate lists is to never create or destroy an aggregate list manually. The `Aggregatable` concern ensures that aggregate lists are created and destroyed automatically.

When a user creates their first regular list, an aggregate list will be automatically created for them and set as that list's aggregate list. Subsequent lists of the same class belonging to the same user should be created with that as the aggregate list:

```ruby
game.aggregate_wish_list.child_lists.create!(title: 'My Title')
```

When a user destroys a regular list, and it is their last regular list of that class, the aggregate list will also be destroyed.

### Updating Aggregate Lists

The `Aggregatable` module does not automatically update an aggregate list when an item is added, removed, or modified on a child list, however, it does provide methods that you can use to do this updating. Updating is a core feature of aggregate lists but fully implementing it in the models proved too magical and was leading to a lot of complexity in the code.

#### Adding an Item to a Child List

When an item is added to a regular list, the corresponding aggregate list should also be updated. This can be done using the `#add_item_from_child_list` method, which handles all logic around adding items. This method will raise an `Aggregatable::AggregateListError` if it is called on a regular list.

```ruby
aggregate_list.add_item_from_child_list(item)
```

There are two possible cases: there is an item already on the aggregate list with the same description as the item being added, or there is not.

##### When There Is No Exising Item

If there is no item with the same description on the aggregate list already, one should be created on the aggregate list with the same attributes. Note that aggregate lists no longer have `notes` values.

##### When There Is an Existing Item

If there is an item with the same description on the aggregate list already, the `quantity` of the item on the aggregate list will be increased by the quantity of the item being added.

One of two things will happen with the `unit_weight` value:

1. If the new `unit_weight` is `nil`, nothing will happen. This implies that, once a unit weight is set, it can be changed but not unset and any new matching items added will have the same unit weight as existing items.
2. If the new `unit_weight` is not `nil`, `unit_weight` will be updated on all list items that belong to the same game and have the same description, not just the aggregate list item.

Setting an invalid `quantity` or `unit_weight` will result in an `Aggregatable::AggregateListError`.

#### Removing an Item from a Child List

When an item is removed from a regular list, the corresponding aggregate list should also be updated. this can be done using the `#remove_item_from_child_list` method, which handles all logic around removing items. This method will raise an `Aggregatable::AggregateListError` if it is called on a regular list.

```ruby
aggregate_list.remove_item_from_child_list(item)
```

There are two possible cases:

1. The item on the aggregate list has the same quantity as the item being removed (meaning there is no other item with the same `description` on any of the aggregate list's children).
2. The item on the aggregate list has a quantity greater than that of the item being removed (meaning there's another item with the same `description` on another one of the aggregate list's children).

If the item passed in is not on the aggregate list, or if its quantity is greater than the quantity on the aggregate list, an `Aggregatable::AggregateListError` will be raised.

##### When the Quantity Is Equal

When the quantity of an item on the aggregate list is equal to the quantity of the list item being removed, the item is removed from the aggregate list.

##### When the Quantity Is Greater

When the quantity of an item on the aggregate list is greater than the quantity of the list item being removed, the quantity is updated on the aggregate list item.

The quantity of the aggregate list item is reduced by the amount of the quantity of the item being removed. Since aggregate list items have no `notes` value, this value is not changed.

#### Editing an Item on a Child List

There are three values that can be edited on a child list item: `notes`, `quantity`, and `unit_weight`. Any or all may be updated at a given time. The aggregate list values can be updated using the `#update_item_from_child_list` method. In order to call this method, you'll two arguments:

* The `description` of the item being edited (to find on the aggregate list - remember that description should not be editable)
* A hash of changed attributes, with possible key/value pairs as follows:
  * `quantity: { to: <initial>, from: <final> }`
  * `unit_weight: { to: <final> }`

Either or both of the keys in the `changed_attributes` hash may be missing or blank. Note that, for the `quantity` value, the initial and final values are the initial and final quantities of the _regular_ list item, not the aggregate list item.

The method will raise an `Aggregatable::AggregateListError` if called on a regular list or if the item being edited does not appear on the aggregate list.

##### Updating the Quantity

Once the item is found on the aggregate list, its `quantity` will be _increased_ by the difference between `quantity[:to]` and `quantity[:from]`. If `quantity[:to]` < `quantity[:from]`, the difference will be negative and the `quantity` therefore decreased.

##### Updating the Notes

In the past, the aggregate list item also tracked notes from items on its child lists. However, this functionality proved too complex and buggy, and it was easier just to remove it. Now, `notes` values are ignored when adding, updating, or removing items from aggregate lists.

##### Updating the Unit Weight

If the unit weight value has been updated and the new value is either (a) `nil` or (b) numeric and at least zero, the unit weight will be updated not only on the requested list item and corresponding aggregate list item, but on all items that match the description and belong to the same game. This is to make sure that list items don't get out of sync with the aggregate list while still enabling `unit_weight` to be edited. If `unit_weight[:to]` is set to `nil`, the unit weight will be unset on all corresponding list items.

## List Model Requirements

Before including the `Aggregatable` module in your class, you will need to define the `list_item_class_name` class method. The method definition will need to be above where you include the module since it is used in the module's `included` block.

## List Item Model Requirements

Before including the `Listable` module in your class, you will need to define the `list_class` and `list_table_name` class methods. The method definitions will need to be above where you include the module since they are used in the module's `included` block.

## Aggregatable

The `Aggregatable` module provides aggregate list functionality to a list model.

### Associations

* Association to `:user` (`belongs_to :user`)
* Association to `:aggregate_list` (`belongs_to :aggregate_list, foreign_key: :aggregate_list_id`)
* Association to `:child_lists` (`has_many :child_lists`)

Note that the `:aggregate_list` and `:child_lists` associated both belong to the same class as the aggregate list.

### Scopes

* `::aggregate_first` (returns lists with the aggregate list first)
* `::includes_items` (eager loads list items with the list)

### Validations

The `Aggregatable` concern validates that no list that is not an aggregate list can be named "All Items". List names are case-insensitive so this applies to any casing. Titles may contain "all items" (with any casing) as long as they don't consist entirely of that phrase.

The concern also includes a validation verifying that the user has only one aggregate list.

Finally, there are validations ensuring that the aggregate list is present for any regular list and that the list set as aggregate list is, in fact, an aggregate list.

### Hooks

The `Aggregatable` concern introduces several hooks to manage aggregate list behaviour.

#### before_validation

Before a regular list is created, if the user does not have an existing aggregate list, the aggregate list is created and set as the aggregate list for the regular list being created. This hook only runs for regular lists and nothing happens if the aggregate list already exists or the list is being updated as opposed to created.

#### before_save

The `#abort_if_aggregate_changed` hook ensures that the `aggregate` status of a list cannot be changed once the list has been created.

The `#remove_aggregate_list_id` hook ensures that aggregate lists do not belong to aggregate lists.

The `#set_title_to_all_items` hook sets the title to "All Items" if the list is an aggregate list.

#### before_destroy

The `#abort_if_aggregate` hook prevents aggregate lists that have extant children from being destroyed.


#### after_destroy

The `#destroy_aggregate_list` hook ensures that aggregate lists are destroyed when their last child is.

### Methods

#### `#add_item_from_child_list(item)`

Should be called on an aggregate list any time an item is added to one of its child lists. Handles logic for creating or combining list items on the aggregate list. Raises an `Aggregatable::AggregateListError` if called on a regular list. Returns the created or updated list item.

#### `#remove_item_from_child_list(item)`

Should be called on an aggregate list any time an item is removed/destroyed from one of its child lists. Handles logic for removing or updating list items on the aggregate list. Raises an `Aggregatable::AggregateListError` if called on a regular list. Returns the updated item from the aggregate list if its quantity is higher than that of the item removed and  otherwise `nil`.

#### `update_item_from_child_list(description, changed_attributes = {})`

Should be called on an aggregate list any time an item is updated on a child list. Raises an `Aggregatable::AggregateListError` if called on a regular list. Handles logic for updating items that already exist on a child list. Returns the updated list item from the aggregate list.

Arguments:

* `description`: The `description` of the item that has been changed (descriptions are not editable).
* `changed_attributes`: A hash indicating what attributes have been changed, with the following possible key/value pairs:
  * `quantity: { from: <initial>, to: <final> }`: Note that the values given should be for the regular list item being updated, not the aggregate list item
  * `unit_weight: { to: <final> }`: The new `unit_weight` value of the item that has been changed; may be `nil` or a numeric value of at least 0

#### `aggregate_list`

Returns the aggregate list to which the wish list belongs. Is `nil` for aggregate lists.

#### `child_lists`

If called on an aggregate list, returns all its the associated lists. Is empty for regular lists.

### What's Automatic and What's Not

`Aggregatable` provides associations, validations, hooks, and scopes on the parent model out of the box. It doesn't provide an automatic mechanism to keep aggregate list _items_ up-to-date with their child lists' models. You will need to use the `#add_item_from_child_list`, `#remove_item_from_child_list`, and `#update_item_from_child_list` methods to do that any time you add, remove, or edit a list item on one of the child lists.

## Listable

The `Listable` concern provides list item functionality to lists' child models.

### Associations

* Association to `:list` (`belongs_to :list`, specifies class name using `self.list_class` method defined on each list item class)

### Scopes

* `::index_order` (returns list items in descending `:updated_at` order)
* `::belonging_to_game(game)` (returns all list items of the given class belonging to the given game)
* `::belonging_to_user(user)` (returns all list items of the given class belonging to the given user)

### Validations

The `Listable` concern provides the following validations.

* `description`: Verifies that the description is present and unique on the list it is on (descriptions are case insensitive)
* `quantity`: Verifies that the quantity is present and is an integer greater than 0
* `unit_weight`: Verifies that the unit weight is a number greater than or equal to zero; `nil` values are allowed
* `notes`: Verifies that only regular list items, and not aggregate list items, can have non-`nil` `notes` values

There is an additional validation that prevents the description from being changed on an existing item (i.e., the description is set on `create` and cannot be changed on `update`).

### Hooks

List items need a way to clean up automatically edited `notes` values. Listable provides a `before_save` hook that calls a `#clean_up_notes` method accounting for the following cases:

* Leading `" -- "` (should be removed)
* Trailing `" -- "` (should be removed)
* Multiple consecutive `" -- "` in the middle of the list (should be turned into just one separator)
* A single `"--"` (should be removed and saved as `nil`)

For example:

* `" -- notes 2"` will be changed to `"notes 2"`
* `"notes 1 -- "` will be changed to  `"notes 1"`
* `"notes 1 --  -- -- notes 3"` will be changeed to `"notes 1 -- notes 3"`
* `"--"` will be changed to `nil`

### Methods

The `Listable` concern implements `::combine_or_new` and `::combine_or_create!` class methods. These methods look for a model on the same list matching the description passed in as an attribute. If no item on the same list matches that description, a new one is instantiated (or created). If there is a matching item on the same list, the quantity passed in will be added to the existing item's quantities and the notes fields on the existing and new items will be updated to aggregate the notes for both items. The `notes` field will only be aggregated when combining items on a regular list; aggregate list items always have a `notes` value of `nil`. The `unit_weight` will be set to the value set in the attributes passed into `::combine_or_new`, if that value is defined and not `nil`.
