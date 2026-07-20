# Wish List Items

Wish list items represent the items on a [wish list](/docs/api/resources/wish-lists.md). Wish list items on regular lists can be created, updated, and destroyed through the API. Wish list items on aggregate wish lists are managed automatically as the items on their child lists change. Each wish list item belongs to a particular list and will be destroyed if the list is destroyed.

There are no read routes (`GET /wish_list_items`, `GET /wish_list/:wish_list_id/wish_list_items`, or `GET /wish_list_items/:id`) for wish list items since all wish list items are returned with the lists they are on when requests are made to the list routes. There are, however, routes to create, update, and destroy wish list items.

All requests to wish list item endpoints must be [authenticated](/docs/api/resources/authorization.md).

## Automatically Managed Aggregate Lists

Skyrim Inventory Management makes use of automatically managed aggregate lists to help users track an aggregate of what items they need for different properties or purposes in each game. The aggregate list is created automatically when the client creates a the first regular wish list for a game, and is destroyed automatically when the client deletes the game's last regular wish list. When items are added, updated, or destroyed from any of a game's regular lists, aggregate list items are updated as described in this section.

(Ensuring automatic management of aggregate lists does require some work on the part of SIM developers. If you are working on lists in SIM and would like information on how to keep them synced, head over to the [`Aggregatable` docs](/docs/aggregate-lists.md).)

### Creating a New List Item

If the client requests a new list item be created on a regular list, one of the following things will happen:

* If there is not an item with the same (case-insensitive) `description` on the aggregate list, then an item with the same `description`, `quantity`, and `unit_weight` will be created on the aggregate list.
* If there is an item with the same (case-insensitive) `description` on the aggregate list, then that item will be updated:
  * The `description` will not be changed
  * The `quantity` will be increased by the quantity of the new list item
  * The `unit_weight` will be changed to the new item's `unit_weight` unless that value is `null`
  * The `notes` value of the aggregate item will remain unchanged as `null`

If the new item sets a `unit_weight` that is not `null` and is different to the `unit_weight` of any existing matching list items belonging to the same game, those items will also be updated to have the same unit weight as the new item.

### Updating a List Item

When a client updates a list item on a regular list for a given game, one (or more) of the following things will happen:

* If the `quantity` is increased, the `quantity` of the item on the aggregate list will be increased by the same amount
* If the `quantity` is decreased, the `quantity` of the item on the aggregate list will be decreased by the same amount
* If the `quantity` has not changed, the `quantity` of the item on the aggregate list will also be unchanged
* If the `notes` are changed, this will not be updated on the aggregate list, whose `notes` will remain `null`
* If the `unit_weight` is changed to `null` or a valid numeric value, the value will be updated on the aggregate list item as well as any other list items with the same (case-insensitive) description belonging to the same game

### Destroying a List Item

When a client destroys a list item on a regular wish list, one of the following things will happen:

* If the quantity of the item on the aggregate wish list for the same game is higher than the quantity of the item deleted (i.e., if there is another matching item on a different list), the aggregate list item's quantity will be decreased by the amount of the quantity of the deleted item.
* If the quantity on the aggregate wish list is equal to the quantity of the item deleted (i.e., if there is not another matching item on a different list), the item on the aggregate wish list will be deleted as well.

## Endpoints

The following endpoints are available to manage wish list items:

* [`POST /wish_lists/:wish_list_id/wish_list_items`](#post-wish_listswish_list_idwish_list_items)
* [`PATCH|PUT /wish_list_items/:id`](#patchput-wish_list_itemsid)
* [`DELETE /wish_list_items/:id`](#delete-wish_list_itemsid)

## POST /wish_lists/:wish_list_id/wish_list_items

Creates a wish list item on the given list if the wish list with the given ID:

1. Exists
2. Belongs to the authenticated user
3. Is not an aggregate list AND
4. Does not have an existing wish list item with the same description

If the first three conditions are met but the list does have an existing wish list item with a matching description, `quantity` and `notes` are updated on the existing item to aggregate the values. If the value of `unit_weight` differs from the value on the existing item and is not `null`, the existing item and any other items with the same description belonging to the same game will have their `unit_weight` updated.

In both cases, the aggregate list for the same game is also updated to reflect the new `quantity` and `unit_weight`. Again, aggregate lists do not track `notes`.

Allowed fields are:

* `description` (string, required): A name or description of the item on the list
* `quantity` (integer, required): The quantity of the item
* `notes` (string, optional): Any notes about the item or what it is for
* `unit_weight` (decimal, optional): The unit weight of the item as given in the game, precise to one decimal place

A successful response will return a JSON array of all changed wish lists for the game to which the created or updated list item ultimately belongs, including all the list items on each list.

### Example Request

```
POST /wish_lists/72/wish_list_items
Authorization: Bearer xxxxxxxxxxx
Content-Type: application/json
{
  "description": "Ebony sword",
  "quantity": 7,
  "notes": "To enchant with 'Absorb Health'"
}
```

### Success Responses

#### Statuses

* 201 Created
* 200 OK

#### Example Body

If there is no item with a matching description on the requested wish list, a new item will be created and the server will return a 201 response. If there is an item with a matching description, its notes and quantity will be combined with the notes and quantity in the client request and a 200 response will be returned.

The body for both responses is a JSON array containing all _changed_ wish lists for the game to which the created or updated list item ultimately belongs, i.e., those that have had items added, updated, or removed. Each wish list includes its list items.

```json
[
  {
    "id": 43,
    "playthrough_id": 8234,
    "aggregate": true,
    "aggregate_list_id": null,
    "title": "All Items",
    "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "list_items": [
      {
        "list_id": 43,
        "description": "Unenchanted ebony sword",
        "quantity": 1,
        "notes": null,
        "unit_weight": null,
        "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
        "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
      },
      {
        "list_id": 43,
        "description": "Iron ingot",
        "quantity": 4,
        "notes": null,
        "unit_weight": 1.0,
        "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
        "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
      }
    ]
  },
  {
    "id": 46,
    "playthrough_id": 8234,
    "aggregate": false,
    "aggregate_list_id": 43,
    "title": "Lakeview Manor",
    "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "list_items": [
      {
        "list_id": 46,
        "description": "Unenchanted ebony sword",
        "quantity": 1,
        "notes": "Need an unenchanted sword to start Companions questline",
        "unit_weight": null,
        "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
        "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
      },
      {
        "list_id": 46,
        "description": "Iron ingot",
        "quantity": 3,
        "notes": "3 locks",
        "unit_weight": 1.0,
        "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
        "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
      }
    ]
  }
]
```

### Error Responses

Four error responses are possible.

#### Statuses

* 404 Not Found
* 405 Method Not Allowed
* 422 Unprocessable Entity
* 500 Internal Server Error

#### Example Bodies

No body will be returned with a 404 error, which is returned if the specified wish list doesn't exist or doesn't belong to the authenticated user.

A 405 error, which is returned if the specified wish list is an aggregate wish list, comes with the following body:
```json
{
  "errors": ["Cannot manually manage items on an aggregate wish list"]
}
```

A 422 error, returned as a result of a validation error, includes whichever errors prevented the list item from being created:
```json
{
  "errors": [
    "Quantity must be a number",
    "Quantity must be greater than zero",
    "Description is required"
  ]
}
```

A 500 error response, which is always a result of an unforeseen problem, includes the error message:
```json
{
  "errors": ["Something went horribly wrong"]
}
```

## PATCH|PUT /wish_list_items/:id

Updates a given wish list item provided the list the item is on:

1. Exists
2. Belongs to the authenticated user AND
3. Is not an aggregate list

When this happens, the corresponding list item on the aggregate list is also automatically updated to stay synced with the other lists. When the aggregate list is synced, the `notes` value is left as `null` as this is a value aggregate lists no longer track.

Requests may specify up to three fields to update:

* `quantity` (integer, greater than zero)
* `notes` (any string)
* `unit_weight` (decimal, 1 decimal place, greater than or equal to zero)

Requests attempting to update `description` will result in a validation error.

When updating `unit_weight`, the `unit_weight` value will be updated for all wish list items belonging to the same game and matching the description. This is to prevent the aggregate list from getting out of sync with the values on its child list items.

This route supports both `PATCH` and `PUT` requests. Application behaviour does not differ depending on which method is used.

### Example Requests

Request bodies must contain a `"wish_list_item"` key containing attributes to be changed. Request bodies lacking this key may result in an error or unexpected behaviour. If the `"wish_list_item"` object is empty, the item will not be changed. Attributes that can be changed include:

* `quantity` (integer greater than zero)
* `notes` (string)
* `unit_weight` (`null` or decimal greater than or equal to zero with up to one decimal place)

#### PATCH Requests

```
PATCH /wish_list_items/72
Authorization: Bearer xxxxxxxxxxx
Content-Type: application/json
{
  "wish_list_item": {
    "quantity": 7,
    "notes": "To enchant with 'Absorb Health'"
  }
}
```

#### PUT Requests

```
PUT /wish_list_items/72
Authorization: Bearer xxxxxxxxxxx
Content-Type: application/json
{
  "wish_list_item": {
    "quantity": 7,
    "notes": "To enchant with 'Absorb Health'"
  }
}
```

### Success Responses

#### Statuses

* 200 OK

#### Example Body

The body is a JSON array containing all wish list items modified in the course of handling the request. Clients should take note of each item's `list_id` value to associate the item to a wish list. Note that, if an item's unit weight is updated, this weight will be updated on any lists with a corresponding list item, so there may be more than two list items included in the response.

```json
[
  {
    "list_id": 43,
    "description": "Unenchanted ebony sword",
    "quantity": 1,
    "notes": null,
    "unit_weight": null,
    "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
  },
  {
    "list_id": 46,
    "description": "Unenchanted ebony sword",
    "quantity": 1,
    "notes": "Need an unenchanted sword to start Companions questline",
    "unit_weight": null,
    "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
  }
  }
]
```

### Error Responses

Four error responses are possible.

#### Statuses

* 404 Not Found
* 405 Method Not Allowed
* 422 Unprocessable Entity
* 500 Internal Server Error

#### Example Bodies

No body will be returned with a 404 error, which is returned if the specified wish list item doesn't exist or doesn't belong to the authenticated user.

A 405 error, which is returned if the specified wish list item is on an aggregate wish list, comes with the following body:

```json
{
  "errors": ["Cannot manually update list items on an aggregate wish list"]
}
```

A 422 error, returned as a result of a validation error, includes whichever errors prevented the list item from being created:

```json
{
  "errors": [
    "Quantity must be a number",
    "Quantity must be greater than zero"
  ]
}
```

A 500 error response, which is always a result of an unforeseen problem, includes the error message:
```json
{
  "errors": ["Something went horribly wrong"]
}
```

## DELETE /wish_list_items/:id

Deletes the given wish list item provided the item exists and the list it is on:

1. Belongs to the authenticated user AND
2. Is not an aggregate list

When this happens, the corresponding list item on the aggregate list is also automatically destroyed (if the quantity is equal to that of the list item being deleted) or updated (if the quantity on the aggregate list is greater) to stay synced with the other lists. When the aggregate list is synced, the `quantity` will be reduced and the `notes` value will remain `null`.

### Example Request

```
DELETE /wish_list_items/5651
Authorization: Bearer xxxxxxxxxxx
```

### Success Responses

#### Statuses

* 200 OK

#### Example Body

The response body includes the wish list from which the item was deleted as well as the aggregate list, with the aggregate list first.

```json
[
  {
    "id": 43,
    "playthrough_id": 8234,
    "aggregate": true,
    "aggregate_list_id": null,
    "title": "All Items",
    "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "list_items": [
      {
        "list_id": 43,
        "description": "Unenchanted ebony sword",
        "quantity": 1,
        "notes": null,
        "unit_weight": null,
        "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
        "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
      },
      {
        "list_id": 43,
        "description": "Iron ingot",
        "quantity": 3,
        "notes": null,
        "unit_weight": 1.0,
        "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
        "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
      }
    ]
  },
  {
    "id": 46,
    "playthrough_id": 8234,
    "aggregate": false,
    "aggregate_list_id": 43,
    "title": "Lakeview Manor",
    "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "list_items": [
      {
        "list_id": 46,
        "description": "Unenchanted ebony sword",
        "quantity": 1,
        "notes": "Need an unenchanted sword to start Companions questline",
        "unit_weight": null,
        "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
        "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
      },
      {
        "list_id": 46,
        "description": "Iron ingot",
        "quantity": 3,
        "notes": "3 locks",
        "unit_weight": 1.0,
        "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
        "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
      }
    ]
  }
]
```

### Error Responses

Three error responses are possible.

#### Statuses

* 404 Not Found
* 405 Method Not Allowed
* 500 Internal Server Error

#### Example Bodies

No body will be returned with a 404 error, which is returned if the specified wish list item doesn't exist or doesn't belong to the authenticated user.

A 405 error, which is returned if the specified wish list item is on an aggregate wish list, comes with the following body:

```json
{
  "errors": ["Cannot manually delete an item from an aggregate wish list"]
}
```

A 500 error response, which is always a result of an unforeseen problem, includes the error message:

```json
{
  "errors": ["Something went horribly wrong"]
}
```
