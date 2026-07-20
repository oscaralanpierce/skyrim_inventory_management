# Inventory Items

Inventory items represent the items on an [inventory list](/docs/api/resources/inventory-lists.md). Inventory items on regular lists can be created, updated, and destroyed through the API. Inventory items on aggregate inventory lists are managed automatically as the items on their other lists change. Each inventory item belongs to a particular list and will be destroyed if the list is destroyed.

There are no read routes (`GET /inventory_items`, `GET /inventory_list/:inventory_list_id/inventory_items`, or `GET /inventory_items/:id`) for inventory items since all inventory items are returned with the lists they are on when requests are made to the list routes. There are, however, routes to create, update, and destroy inventory items.

All requests to inventory item endpoints must be [authenticated](/docs/api/resources/authorization.md).

## Automatically Managed Aggregate Lists

Skyrim Inventory Management makes use of automatically managed aggregate lists to help users track an aggregate of what items they need for different properties in each playthrough. The aggregate list is created automatically when the client creates a the first regular inventory list for a playthrough, and is destroyed automatically when the client deletes the playthrough's last regular inventory list. When items are added, updated, or destroyed from any of a playthrough's regular lists, aggregate list items are updated as described in this section.

(Ensuring automatic management of aggregate lists does require some work on the part of SIM developers. If you are working on lists in SIM and would like information on how to keep them synced, head over to the [`Aggregatable` docs](/docs/aggregate-lists.md).)

### Creating a New List Item

If the client requests a new item be created on a regular inventory list, one of the following things will happen:

* If there is not an item with the same (case-insensitive) `description` on the aggregate list, then an item with the same `description`, `quantity`, and `unit_weight` will be created on the aggregate list. `notes` values on aggregate lists are always `null`.
* If there is an item with the same (case-insensitive) `description` on the aggregate list, then that item will be updated:
  * The `description` will not be changed
  * The `quantity` will be increased by the quantity of the new item
  * The `unit_weight` will be changed to the new item's `unit_weight` unless that value is `null`
  * The `notes` value on the aggregate list item will remain `null`

If the new item sets a `unit_weight` that is not `null` and is different to the `unit_weight` of any existing matching items belonging to the same playthrough, those items will also be updated to have the same unit weight as the new item.

### Updating a List Item

When a client updates a item on a regular list for a given playthrough, one (or two) of the following things will happen:

* If the `quantity` is increased, the `quantity` of the item on the aggregate list will be increased by the same amount
* If the `quantity` is decreased, the `quantity` of the item on the aggregate list will be decreased by the same amount
* If the `quantity` has not changed, the `quantity` of the item on the aggregate list will also be unchanged
* If the `unit_weight` is changed, the value will be updated on the aggregate list item as well as any other items with the same (case-insensitive) description belonging to the same playthrough. This is true whether the `unit_weight` is `null` or another value

Again, aggregate list items do not track `notes` of child lists, so these values will not be updated.

### Destroying a List Item

When a client destroys an item on a regular inventory list, one of the following things will happen:

* If the quantity of the item on the aggregate inventory list for the same playthrough is higher than the quantity of the item deleted (i.e., if there is another matching item on a different list), the aggregate list item's quantity will be decreased by the amount of the quantity of the deleted item.
* If the quantity on the aggregate inventory list is equal to the quantity of the item deleted (i.e., if there is not another matching item on a different list), the item on the aggregate inventory list will be deleted as well.

## Endpoints

The following endpoints are available to manage inventory items:

* [`POST /inventory_lists/:inventory_list_id/inventory_items`](#post-inventory_listsinventory_list_idinventory_items)
* [`PATCH|PUT /inventory_items/:id`](#patchput-inventory_itemsid)
* [`DELETE /inventory_items/:id`](#delete-inventory_itemsid)

## POST /inventory_lists/:inventory_list_id/inventory_items

Creates an inventory item on the given list if the inventory list with the given ID:

1. Exists
2. Belongs to the authenticated user
3. Is not an aggregate list AND
4. Does not have an existing inventory item with the same description

If the first three conditions are met but the list does have an existing inventory item with a matching description, `quantity` and `notes` are updated on the existing item to aggregate the values. If the value of `unit_weight` differs from the value on the existing item and is not `null`, the existing item and any other items with the same description belonging to the same playthrough will have their `unit_weight` updated.

In both cases, the aggregate list for the same playthrough is also updated to reflect the new `quantity` and `unit_weight`.

Allowed fields are:

* `description` (string, required): A name or description of the item on the list
* `quantity` (integer, required): The quantity of the item
* `unit_weight` (decimal, optional): The unit weight of the item as given in the game, precise to one decimal place
* `notes` (string, optional): Any notes about the item or what it is for

A successful response will return a JSON array of any items created or updated while handling the request. These may come in any order and will include the item requested, the aggregate list item, and, if `unit_weight` is given in the request, any other items with the same description belonging to the same playthrough that have had their `unit_weight` changed.

### Example Request

```
POST /inventory_lists/72/inventory_items
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

If there is no item with a matching description on the requested inventory list, a new item will be created and the server will return a 201 response. If there is an item with a matching description, its notes and quantity will be combined with the notes and quantity in the client request and a 200 response will be returned.

The body for both responses is a JSON array containing all items that were created or updated while handling the request, including the requested item, the corresponding aggregate list item, and, if setting `unit_weight`, any other items with the same description belonging to the same playthrough.
```json
[
  {
    "id": 87,
    "list_id": 238,
    "description": "Ebony sword",
    "quantity": 9,
    "unit_weight": 14.0,
    "notes": null,
    "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Fri, 02 Jul 2021 12:04:27.161932000 UTC +00:00"
  },
  {
    "id": 126,
    "list_id": 237,
    "description": "Ebony sword",
    "quantity": 7,
    "unit_weight": 14.0,
    "notes": "To enchant with 'Absorb Health'",
    "created_at": "Fri, 02 Jul 2021 12:04:27.161932000 UTC +00:00",
    "updated_at": "Fri, 02 Jul 2021 12:04:27.161932000 UTC +00:00"
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

No body will be returned with a 404 error, which is returned if the specified inventory list doesn't exist or doesn't belong to the authenticated user.

A 405 error, which is returned if the specified inventory list is an aggregate inventory list, comes with the following body:
```json
{
  "errors": [
    "Cannot manually manage items on an aggregate inventory list"
  ]
}
```

A 422 error, returned as a result of a validation error, includes whichever errors prevented the item from being created:
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

## PATCH|PUT /inventory_items/:id

Updates a given inventory item provided the list the item is on:

1. Exists
2. Belongs to the authenticated user AND
3. Is not an aggregate list

When this happens, the corresponding item on the aggregate list is also automatically updated to stay synced with the other lists. When the aggregate list is synced, the `notes` value remains `null` regardless of the value on the regular list item.

Requests may specify up to three fields to update:
* `quantity` (integer, greater than zero)
* `notes` (any string)
* `unit_weight` (decimal, 1 decimal place, greater than or equal to zero)

Requests attempting to update `description` will result in a validation error.

When updating `unit_weight`, the `unit_weight` value will be updated for all inventory items belonging to the same playthrough and matching the description. This is to prevent the aggregate list from getting out of sync with the values on its child list items.

This route supports both `PATCH` and `PUT` requests. The only difference between these requests is the HTTP method; requests are handled by the same code regardless of the method.

### Example Requests

Request bodies must contain a `"inventory_item"` key containing attributes to be changed. Attributes that can be changed include:

* `quantity` (integer greater than zero)
* `notes` (string)
* `unit_weight` (decimal greater than or equal to zero with up to one decimal place)

Using a `PATCH` request:
```
PATCH /inventory_items/72
Authorization: Bearer xxxxxxxxxxx
Content-Type: application/json
{
  "inventory_item": {
    "quantity": 7,
    "notes": "To enchant with 'Absorb Health'"
  }
}
```

Using a `PUT` request:
```
PUT /inventory_items/72
Authorization: Bearer xxxxxxxxxxx
Content-Type: application/json
{
  "inventory_item": {
    "quantity": 7,
    "notes": "To enchant with 'Absorb Health'"
  }
}
```

### Success Responses

#### Statuses

* 200 OK

#### Example Body

The body is a JSON array containing all items that were updated while handling the request, including the requested item, the corresponding aggregate list item, and, if setting `unit_weight`, any other items with the same description belonging to the same playthrough. (This is because, when `unit_weight` is set on any item, all matching items belonging to the same playthrough are updated with the same value.)
```json
[
  {
    "id": 87,
    "list_id": 236,
    "description": "Ebony sword",
    "quantity": 9,
    "unit_weight": 14.0,
    "notes": null,
    "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Fri, 02 Jul 2021 12:04:27.161932000 UTC +00:00"
  },
  {
    "id": 126,
    "list_id": 237,
    "description": "Ebony sword",
    "quantity": 7,
    "unit_weight": 14.0,
    "notes": "To enchant with 'Absorb Health'",
    "created_at": "Fri, 18 Jun 2021 02:32:31.762797000 UTC +00:00",
    "updated_at": "Fri, 02 Jul 2021 12:04:27.161932000 UTC +00:00"
  },
  {
    "id": 102,
    "list_id": 238,
    "description": "Ebony sword",
    "quantity": 7,
    "unit_weight": 14.0,
    "notes": "To sell",
    "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Fri, 02 Jul 2021 12:04:27.161932000 UTC +00:00"
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

No body will be returned with a 404 error, which is returned if the specified inventory item doesn't exist or doesn't belong to the authenticated user.

A 405 error, which is returned if the specified inventory item is on an aggregate inventory list, comes with the following body:
```json
{
  "errors": [
    "Cannot manually update list items on an aggregate inventory list"
  ]
}
```

A 422 error, returned as a result of a validation error, includes whichever errors prevented the item from being created:
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

## DELETE /inventory_items/:id

Deletes the given inventory item provided the item exists and the list it is on:

1. Belongs to the authenticated user AND
2. Is not an aggregate list

When this happens, the corresponding item on the aggregate list is also automatically destroyed (if the quantity is equal to that of the item being deleted) or updated (if the quantity on the aggregate list is greater) to stay synced with the other lists. When the aggregate list is synced, the `quantity` will be reduced.

### Example Request

```
DELETE /inventory_items/5651
Authorization: Bearer xxxxxxxxxxx
```

### Success Responses

#### Statuses

* 200 OK
* 204 No Content

#### Example Body

The API will return a 204 response if the item has been destroyed along with the corresponding item on the aggregate list. This response does not include a body. On the other hand, if the aggregate list item has been updated rather than destroyed, it will be returned and the status code will be 200.

Example 200 response body containing the updated aggregate list item:
```json
{
  "id": 87,
  "list_id": 238,
  "description": "Ebony sword",
  "quantity": 9,
  "unit_weight": 14.0,
  "notes": null,
  "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
  "updated_at": "Fri, 02 Jul 2021 12:04:27.161932000 UTC +00:00"
}
```

### Error Responses

Three error responses are possible.

#### Statuses

* 404 Not Found
* 405 Method Not Allowed
* 500 Internal Server Error

#### Example Bodies

No body will be returned with a 404 error, which is returned if the specified inventory item doesn't exist or doesn't belong to the authenticated user.

A 405 error, which is returned if the specified inventory item is on an aggregate inventory list, comes with the following body:
```json
{
  "errors": [
    "Cannot manually delete an item from an aggregate inventory list"
  ]
}
```

A 500 error response, which is always a result of an unforeseen problem, includes the error message:
```json
{
  "errors": ["Something went horribly wrong"]
}
```
