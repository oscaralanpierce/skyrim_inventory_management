# 0001. Stop Syncing Notes on Aggregate Lists

## Date

2023-04-10

## Approved By

@danascheider

## Decision

Shopping list and inventory items on aggregate lists will no longer aggregate the `notes` values from items on their child lists.

## Glossary

- **Aggregate List:** A special [shopping](/app/models/shopping_list.rb) or [inventory](/app/models/inventory_list.rb) list that automatically tracks items on all other lists belonging to the same game
- **Aggregate List Item:** A [shopping](/app/models/shopping_list_item.rb) or [inventory](/app/models/inventory_item.rb) list item on an aggregate list
- **Child List:** A non-aggregate shopping or inventory list belonging to the same game as an aggregate list and having its list items aggregated on that aggregate list; a single aggregate list can have one or more child lists

## Context

Currently, aggregate list items track all data about the items on the child list: `description` (which is the same for all corresponding items and is used to identify which items should be aggregated together), `unit_weight`, and `notes`. `notes` is by far the most complex aggregation to perform because of the number of edge cases that can come up around updating them.

The most obvious challenge is that, when an item with notes exists on a list and a user creates a new item with the same description on that list, the new item is wrapped into the old one, increasing quantity, updating unit weight if appropriate, and combining `notes` values. The aggregate list then also has to take the new value into account and update accordingly. Likewise, if an item with the same `description` is added to another list, its notes also have to be aggregated on the aggregate list. This can complicate things, particularly since the order in which notes occur on the aggregate list is not guaranteed.

The ultimate motivation for this decision was the investigation of [this bug](https://trello.com/c/KlCqMnkY/274-investigate-bug-with-combining-notes-values-on-aggregate-lists), which included a number of edge cases by itself, each of which then revealed additional edge cases to handle. Fixing the bugs would've made our code really complex and bug-prone. Since `notes` are specific to individual list items anyway, it's unclear what benefits this would provide to make it worth the trouble.

## Considerations

In deciding whether to make the change, we considered the following factors:

- How much value is being provided by having `notes` aggregated on the aggregate list items
- The complexity of code being used to aggregate these values
- The likelihood of problems coming up from this code (some of which have already occurred)
- Changes we are likely to make in the near future that would involve working on this code

### Value Provided

It's unclear what, if any, value is added by having notes aggregated on aggregate list items. Notes are already visible on the child list items, and don't necessarily make sense out of that context.

### Implementation Complexity

For the minimal value provided by aggregating notes on aggregate list items, the implementation is quite complex. There are numerous edge cases to consider:

- Two regular list items have identical notes and only one occurrence should be updated or removed
- Notes values are not in the same order on the aggregate list as they are on the regular lists, making regex replacement difficult when managing list items
- A user adds notes containing the character sequence ` -- `, which was being used as the separator for notes from different list items and would lead to those notes being interpreted by the program as separate values

We identified several similar edge cases that would result in ugly and brittle code.

### Likelihood of Problems

The possibility of problems coming up with this code is not a hypothetical, it is a reality. We have already had significant bugs with note aggregation logic. In the course of fixing these bugs, we identified additional edge cases that could cause problems. The aggregation of `notes` values is just too complex and has too many edge cases not to be buggy.

### Future Changes

We've identified that, in the future, we will need to retire the [Aggregatable](/app/models/concerns/aggregatable.rb) and [Listable](/app/models/concerns/listable.rb) concerns, which handle list aggregation behaviour, because the needs of shopping lists and inventory lists are diverging. There is, in fact, already a [Trello card](https://trello.com/c/wguZkVjg/147-develop-distinct-aggregation-algorithm-for-inventory-lists) for reworking the aggregation algorithm used for inventory items. Since they will be required to have underlying in-game objects, which correspond to specific [canonical models](/docs/canonical_models/README.md), aggregation for inventory items will be based on which items have the same underlying objects and not which have the same description, unit weight, etc.

## Summary

Because of the significant complexity of combining notes on aggregate lists, combined with the limited value add provided by this functionality, we have decided that all aggregate list items will have `nil` notes. This will be enforced by validations.
