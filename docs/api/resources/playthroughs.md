# Playthroughs

Each user in Skyrim Inventory Management can have many playthroughs. The playthrough is the base resource that owns other resources a user may create, such as wish lists and wish list items. All playthrough routes are scoped to the currently authenticated user. There are no admin routes or any way to access, create, remove, or modify data for a user that is not currently authenticated.

## Endpoints

There is currently one endpoint available:

* [`GET /playthroughs`](#get-playthroughs)
* [`POST /playthroughs`](#post-playthroughs)
* [`PATCH|PUT /playthroughs/:id`](#patchput-playthroughsid)
* [`DELETE /playthroughs/:id`](#delete-playthroughsid)

## GET /playthroughs

Retrieves all the playthroughs belonging to the authenticated user and returns them as an array.

### Example Requests

```
GET /playthroughs
Authorization: Bearer xxxxxxxx
```

### Success Responses

#### Statuses

* 200 OK

#### Example Bodies

Success response when the user has no playthroughs:
```json
[]
```

Success response when the user has playthroughs:
```json
[
  {
    "id": 335,
    "user_id": 2301,
    "name": "My Playthrough 1",
    "description": "My first playthrough",
    "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
    "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
  },
  {
    "id": 822,
    "user_id": 2301,
    "name": "My Playthrough 2",
    "description": "My second playthrough",
    "created_at": "Mon, 21 Jun 2021 02:36:27.173881000 UTC +00:00",
    "updated_at": "Mon, 21 Jun 2021 02:36:27.173881000 UTC +00:00"
  }
]
```

### Error Responses

#### Statuses

* 500 Internal Server Error

#### Example Bodies

A 500 response is returned only when an unexpected error has occurred. It returns an array with one or more error messages.
```json
{
  "errors": ["Something went horribly wrong"]
}
```

## POST /playthroughs

Creates a playthrough for the authenticated user with the given attributes. Requests may or may not include JSON request bodies. If a body is included, it should have a `"playthrough"` key whose value is an object. That object can contain the keys `"name"` and `"description"`, both of which are optional. If a `"name"` is not specified, the playthrough will be created with a default name. Default names take the form "My Playthrough N", where _N_ is an integer one higher than the highest existing number in a default name. So if a user has playthroughs named "My Playthrough 1" and "My Playthrough 3", their next default-titled playthrough will be "My Playthrough 4". If a user chooses to specify a name, the name must consist of alphanumeric characters, spaces, commas, hyphens, and/or apostrophes. Other values will result in a 422 response. Additionally, playthrough names must be unique per user.

### Example Requests

Request with no request body (will result in a default name being given to the new playthrough, and an empty description):
```
POST /playthroughs
Authorization: Bearer xxxxxxxx
```

Request with a request body specifying a name and description:
```
POST /playthroughs
Authorization: Bearer xxxxxxxx
Content-Type: application/json
{
  "playthrough": {
    "name": "My Non Default Playthrough Name"
  }
}
```

### Success Responses

#### Statuses

* 201 Created

#### Example Bodies

```json
{
  "id": 83226,
  "user_id": 20082,
  "name": "My Playthrough 1",
  "description": "This could also be null",
  "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
  "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
}
```

### Error Responses

#### Statuses

* 422 Unprocessable Entity
* 500 Internal Server Error

#### Example Bodies

A 422 response results from a validation error when the attributes provided in the request don't fit the requirements of the API. It includes an array of the errors that prevented the playthrough from being created:
```json
{
  "errors": ["Name is already taken"]
}
```

A 500 error will be returned only when an unanticipated error is raised. The response body will include the error message.
```json
{
  "errors": ["Something went horribly wrong"]
}
```

## PATCH|PUT /playthroughs/:id

Update the playthrough with the attributes provided, if the playthrough exists and belongs to the authenticated user. This endpoint accepts both `PUT` and `PATCH` requests.

### Example Request

Request bodies have a single `"playthrough"` key pointing to an object whose keys can include `"name"` and `"description"`. Both of these keys are optional and their values should be strings. The `"name"` must be unique to the user's playthroughs and consist of alphanumeric characters, spaces, hyphens (-), commas (,), and apostrophes (').

Using a PATCH request:
```
PATCH /playthroughs/3892
Authorization: Bearer xxxxxxxx
Content-Type: application/json
{
  "playthrough": {
    "name": "New Name",
    "description": "New description"
  }
}
```

Using a PUT request:
```
PUT /playthroughs/3892
Authorization: Bearer xxxxxxxx
Content-Type: application/json
{
  "playthrough": {
    "name": "New Name",
    "description": "New description"
  }
}
```

### Success Responses

#### Statuses

* 200 OK

#### Example Bodies

A 200 response returns the playthrough as its response body, with the updated attributes.
```json
{
  "id": 83226,
  "user_id": 20082,
  "name": "New Name",
  "description": "This could also be null",
  "created_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00",
  "updated_at": "Thu, 17 Jun 2021 11:59:16.891338000 UTC +00:00"
}
```

### Error Responses

#### Statuses

* 404 Not Found
* 422 Unprocessable Entity
* 500 Internal Server Error

#### Example Bodies

a 404 response, which occurs when the playthrough does not exist or does not belong to the authenticated user, returns no response body.

A 422 response returns the validation errors that prevented the record from being saved:
```json
{
  "errors": ["Name must be unique"]
}
```

A 500 response, which is returned when an unexpected error is returned, returns an error message:
```json
{
  "errors": ["Mistakes were made"]
}
```

## DELETE /playthroughs/:id

Deletes the given playthrough if it exists and belongs to the authenticated user.

### Example Request

```
DELETE /playthroughs/4754
Authorization: Bearer xxxxxxxx
```

### Success Responses

#### Statuses

* 204 No Content

#### Example Bodies

A successful response will not include a body.

### Error Responses

#### Statuses

* 404 Not Found
* 500 Internal Server Error

#### Example Bodies

A 404 response, returned if the playthrough is not found or does not belong to the authenticated user, does not include a response body.

A 500 response, returned if an unexpected error occurs, includes the error message in the body:
```json
{
  "errors": ["Mistakes were made"]
}
```
