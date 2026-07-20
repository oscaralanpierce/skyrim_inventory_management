# Wish Lists

Wish lists represent lists of items a user needs in a given game. Users can have different lists corresponding to different property locations within each game. Games with wish lists also have an aggregate list that includes the combined list items and quantities from all the other lists for that game. Aggregate lists are created, updated, and destroyed automatically. They cannot be created, updated, or destroyed through the API (including to change attributes or to add, remove, or update list items).

Each list contains [wish list items](/docs/api/resources/wish-list-items.md), which are returned with each response that includes the list.

When making requests to update the title of a wish list, there are some validations and automatic transformations to keep in mind:

* Titles must be unique per game - you cannot name two lists the same thing within the same game
* Only an aggregate list can be called "All Items"
* All aggregate lists are called "All Items" and there is no way to rename them something else
* Titles are saved with headline casing regardless of the case submitted in the request (for example, "lOrd of the rINgS" will be saved as "Lord of the Rings")
* If the request includes a blank title, then the title will be saved as "My List N", where N is the integer above the highest nonnegative integer used in an existing "My List" title (so if the game has "My List 1" and "My List 3", the next time the user tries to save a list for that game without a title it will be called "My List 4")
* Leading and trailing whitespace will be stripped from titles before they are saved, so " My List 2  " becomes "My List 2"
* Titles may only contain alphanumeric characters, spaces, hyphens, apostrophes, and commas - any other characters (that aren't leading or trailing whitespace, which will be stripped regardless) cause the API to return a 422 response

Like other resources in SIM, wish lists are scoped to the authenticated user. There is no way to retrieve or manage wish lists for any other user through the API.

## Endpoints

* [`GET /games/:playthrough_id/wish_lists`](#get-gamesplaythrough_idwish_lists)
* [`POST /games/:playthrough_id/wish_lists`](#post-gamesplaythrough_idwish_lists)
* [`PATCH|PUT /wish_lists/:id`](#patchput-wish_listsid)
* [`DELETE /wish_lists/:id`](#delete-wish_listsid)

## GET /games/:playthrough_id/wish_lists

Returns all wish lists for the game indicated by the `:playthrough_id` param, provided the game exists and is owned by the authenticated user. The aggregate wish list will be returned first, followed by the game's other wish lists in reverse chronological order by `updated_at` (i.e., the lists that were edited most recently will be on top).

### Example Request

```
GET /wish_lists
Authorization: Bearer xxxxxxxxxxxxx
```

### Success Responses

#### Statuses

* 200 OK

#### Example Bodies

For a game with no lists:
```json
[]
```
For a game with multiple lists:

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
        "id": 689
        "list_id": 43,
        "description": "Unenchanted ebony sword",
        "quantity": 1,
        "notes": null,
        "unit_weight": null,
        "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
        "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
      },
      {
        "id": 134,
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
        "id": 845,
        "list_id": 46,
        "description": "Unenchanted ebony sword",
        "quantity": 1,
        "notes": "Need an unenchanted sword to start Companions questline",
        "unit_weight": null,
        "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
        "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
      },
      {
        "id": 76,
        "list_id": 46,
        "description": "Iron ingot",
        "quantity": 3,
        "notes": "3 locks",
        "unit_weight": 1.0,
        "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
        "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
      }
    ]
  },
  {
    "id": 52,
    "playthrough_id": 8234,
    "aggregate": false,
    "aggregate_list_id": 43,
    "title": "Severin Manor",
    "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "list_items": [
      {
        "id": 11,
        "list_id": 52,
        "description": "Iron ingot",
        "quantity": 1,
        "notes": "2 hinges",
        "unit_weight": 1.0,
        "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
        "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
      }
    ]
  }
]
```

### Error Responses

In general, no errors are expected to be returned from this endpoint. However, unanticipated problems can always come up.

#### Statuses

* 404 Not Found
* 500 Internal Server Error

#### Example Bodies

A 404 error is the result of the game not being found or not belonging to the authenticated user. It does not include a response body.

A 500 error response, which is always a result of an unforeseen problem, includes the error message:
```json
{
  "errors": ["Something went horribly wrong"]
}
```

## POST /games/:playthrough_id/wish_lists

Creates a new wish list for the specified game if it exists and belongs to the authenticated user. If the game does not already have an aggregate list, an aggregate list will also be created automatically. The response is an array that includes all wish lists that were created. The wish lists are returned with the aggregate list first, if one was created while handling this request, and the regular list the user requested.

The request does not have to include a body. If it does, the body should include a `"wish_list"` object with an optional `"title"` key, the only attribute that can be set on a wish list via this or any endpoint. If you don't include a title, your list will be titled "My List N", where _N_ is an integer equal to one plus the highest numbered default list title you have. For example, if you have lists titled "My List 1", "My List 3", and "My List 4" and you don't specify a title for your new list, your new list will be titled "My List 5".

There are a few validations and automatic changes made to titles:

* Titles must be unique per game - you cannot name two of one game's lists the same thing
* Only an aggregate list can be called "All Items"
* All aggregate lists are called "All Items" and there is no way to rename them something else
* Titles are saved with headline casing regardless of the case submitted in the request (for example, "lOrd of the rINgS" will be saved as "Lord of the Rings")
* If the request includes a blank title, then the title will be saved as "My List N", where N is the integer above the highest integer used in an existing "My List" title (so if the user has "My List 1" and "My List 3", the next time the client creates a list without a title, it will be called "My List 4")

### Example Requests

Request specifying a title:
```
POST games/1455/wish_lists
Authorization: Bearer xxxxxxxxxx
Content-Type: application/json
{
  "wish_list": {
    "title": "Custom Title"
  }
}
```

Request not specifying a title (list will be given a default title as defined above):
```
POST /games/8928/wish_lists
Authorization: Bearer xxxxxxxxxx
Content-Type: application/json
{ "wish_list": {} }
```

Request with no request body (the list will be given a default title as defined above):
```
POST /games/8928/wish_lists
Authorization: Bearer xxxxxxxxxx
```

### Success Responses

#### Statuses

* 201 Created

#### Example Body

##### When an Aggregate List Is Created

```json
[
  {
    "id": 4,
    "user_id": 6,
    "aggregate": true,
    "aggregate_list_id": null,
    "title": "All Items",
    "created_at": "Tue, 15 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Tue, 15 Jun 2021 11:59:16.891338000 UTC +00:00",
    "list_items": []
  },
  {
    "id": 5,
    "user_id": 6,
    "aggregate": false,
    "aggregate_list_id": 4,
    "title": "My List 1",
    "created_at": "Tue, 15 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Tue, 15 Jun 2021 11:59:16.891338000 UTC +00:00",
    "list_items": []
  }
]
```

##### When Only a Regular List Is Created

```json
[
  {
    "id": 5,
    "user_id": 6,
    "aggregate": false,
    "aggregate_list_id": 4,
    "title": "My List 1",
    "created_at": "Tue, 15 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Tue, 15 Jun 2021 11:59:16.891338000 UTC +00:00",
    "list_items": []
  }
]
```

### Error Responses

#### Statuses

* 404 Not Found
* 422 Unprocessable Entity
* 500 Internal Server Error

#### Example Bodies

If the game with the given `playthrough_id` is not found or does not belong to the authenticated user, a 404 response will be returned. This response will have no body.

If duplicate title is given:
```json
{
  "errors": ["Title must be unique per game"]
}
```

If request attempts to create an aggregate list:
```json
{
  "errors": ["Cannot manually create an aggregate wish list"]
}
```

A 500 error response, which is always a result of an unforeseen problem, includes the error message:
```json
{
  "errors": ["Something went horribly wrong"]
}
```

## PATCH|PUT /wish_lists/:id

If the specified wish list exists, belongs to the authenticated user, and is not an aggregate list, updates the title and returns the wish list. Title is the only wish list attribute that can be modified using this endpoint. This endpoint also supports the `PUT` method. There is no  difference in application behaviour whether `PATCH` or `PUT` is used.

### Example Requests

Requests should include a `"wish_list"` object with a `"title"` key. The `"title"` may be `null`; in this case, a default title will be assigned as described [above](#post-gamesplaythrough_idwish_lists). If the `"wish_list"` object is empty or nonexistent, or if no request body is given, the list will not be updated but will be returned as-is. `"title"` is the only attribute that may be set on wish lists via the SIM API.

#### PATCH Requests

Normal usage:

```
PATCH /wish_lists/3
Authorization: Bearer xxxxxxxxxx
Content-Type: application/json
{
  "wish_list": {
    "title": "New List Title"
  }
}
```

Null title (will result in a default title being assigned):

```
PATCH /wish_lists/3
Authorization: Bearer xxxxxxxxxx
Content-Type: application/json
{
  "wish_list": {
    "title": null
  }
}
```

Empty `"wish_list"` object (wish list will be returned as-is):

```
PATCH /wish_lists/3
Authorization: Bearer xxxxxxxxxx
Content-Type: application/json
{
  "wish_list": {}
}
```

#### PUT Requests

Normal usage:

```
PUT /wish_lists/3
Authorization: Bearer xxxxxxxxxx
Content-Type: application/json
{
  "wish_list": {
    "title": "New List Title"
  }
}
```

Null title (will result in a default title being assigned):

```
PUT /wish_lists/3
Authorization: Bearer xxxxxxxxxx
Content-Type: application/json
{
  "wish_list": {
    "title": null
  }
}
```

Empty `"wish_list"` object (wish list will be returned as-is):

```
PUT /wish_lists/3
Authorization: Bearer xxxxxxxxxx
Content-Type: application/json
{
  "wish_list": {}
}
```

### Success Response

#### Statuses

* 200 OK

#### Example Body

```json
{
  "id": 834,
  "user_id": 16,
  "aggregate": false,
  "aggregate_list_id": 833,
  "title": "New List Title",
  "created_at": "Tue, 15 Jun 2021 12:34:32.713457000 UTC +00:00",
  "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
  "list_items": [
    {
      "id": 32,
      "list_id": 834,
      "description": "Ebony sword",
      "quantity": 1,
      "notes": "To enchant with Soul Trap",
      "unit_weight": 14.0,
      "created_at": "Tue, 15 Jun 2021 12:34:32.713457000 UTC +00:00",
      "updated_at": "Tue, 15 Jun 2021 12:34:32.713457000 UTC +00:00"
    }
  ]
}
```

### Error Responses

#### Statuses

* 404 Not Found
* 405 Method Not Allowed
* 422 Unprocessable Entity
* 500 Internal Server Error

#### Example Bodies

For a 404 response, no response body is returned.

For a 422 response due to title uniqueness constraint:

```json
{
  "errors": ["Title must be unique per game"]
}
```

For a 405 response due to attempting to update an aggregate list or convert a regular list to an aggregate list:

```json
{
  "errors": ["Cannot manually update an aggregate wish list"]
}
```

A 500 error response, which is always a result of an unforeseen problem, includes the error message:

```json
{
  "errors": ["Something went horribly wrong"]
}
```

## DELETE /wish_lists/:id

Destroys the given wish list, and any wish list items on it, if it exists and belongs to the authenticated user. If the list to be destroyed is the user's only regular (non-aggregate) wish list, the aggregate list will also be destroyed. The body of a successful response includes an array of deleted list IDs and the updated aggregate list (unless it was also deleted).

### Example Request

```
DELETE /wish_lists/428
Authorization: Bearer xxxxxxxxxxxx
```

### Success Response

#### Statuses

* 200 OK

#### Example Bodies

The response body will be a JSON object with a `"deleted"` key pointing to an array of deleted lists. If only the target list was destroyed, this array will include one member. If the target list was the game's last regular wish list and the aggregate list was therefore also destroyed, the array will include two members. If the aggregate list was not destroyed, it will be returned as well, with its updated list items, under the `"aggregate"` key.

Body including an aggregate list that was not destroyed:

```json
{
  "deleted": [835],
  "aggregate": {
    "id": 834,
    "user_id": 16,
    "aggregate": true,
    "aggregate_list_id": null,
    "title": "All Items",
    "created_at": "Tue, 15 Jun 2021 12:34:32.713457000 UTC +00:00",
    "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "list_items": [
      {
        "id": 32,
        "list_id": 834,
        "description": "Ebony sword",
        "quantity": 1,
        "notes": null,
        "unit_weight": 14.0,
        "created_at": "Tue, 15 Jun 2021 12:34:32.713457000 UTC +00:00",
        "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
      }
    ]
  }
}
```

Body when the aggregate list was also destroyed:

```json
{
  "deleted": [834, 835]
}
```

### Error Responses

If the specified list does not exist or does not belong to the authenticated user, a 404 response will be returned. If the specified list is an aggregate list, a 405 response will be returned.

#### Statuses

* 404 Not Found
* 405 Method Not Allowed
* 500 Internal Server Error

#### Example Bodies

For a 404 response, no response body will be returned.

For a 405 response:

```json
{
  "errors": ["Cannot manually delete an aggregate wish list"]
}
```

A 500 error response, which is always a result of an unforeseen problem, includes the error message:

```json
{
  "errors": ["Something went horribly wrong"]
}
```
