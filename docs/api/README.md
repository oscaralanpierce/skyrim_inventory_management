# API Documentation

Skyrim Inventory Management API offers a range of endpoints allowing users to store, retrieve, and remove data about their inventory and tasks.

## Endpoints

All endpoints accept and return JSON bodies only. Unless otherwise specified, all endpoints are authenticated using an `Authorization` header including the bearer token from Google OAuth. The API is stateless and all requests must be authenticated individually. Requests including a request body should include a `Content-Type` header set to `"application/json"`.

Authorization is handled in a `before_action` on the `ApplicationController`. Unless otherwise indicated, error statuses for all resources can include a 401 response returned from this `before_action`. Any error raised during the validation process, not just failure of token validation itself, will result in a 401 response. The JSON body of this response will include an `"errors"` array with one or more messages that may be helpful for troubleshooting.

## Authorization

See docs:

* [User Authentication](/docs/api/user-authentication.md)

## Resources

The SIM API makes the following RESTful resources available to the client. Note that the `User` model is not exposed as a RESTful resource because Google is the source of truth for profile information.

* [Playthroughs](/docs/api/resources/playthroughs.md)
* [Inventory List Items](/docs/api/resources/inventory-list-items.md)
* [Inventory Lists](/docs/api/resources/inventory-lists.md)
* [Wish List Items](/docs/api/resources/wish-list-items.md)
* [Wish Lists](/docs/api/resources/wish-lists.md)

### Object Modelling Hierarchy

In SIM, users can have any number of playthroughs, which can each have any number of wish lists, which can each have any number of wish list items. An authenticated user can create, access, update, and destroy resources belonging to them. There are currently no admin routes or any way to access resources not belonging to the currently authenticated user (except through direct database access).
