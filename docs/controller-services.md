# Controller Services

The SIM back end uses a controller service pattern to extract heavy controller logic. This pattern is easy to use once you have learnt it. There are three key components: the service class, the result object, and the response object.

## The Service Class

A service class lives in the `/app/controller_services` directory, in a subdirectory for the controller it serves. Consistent with [Zeitwerk](https://medium.com/cedarcode/understanding-zeitwerk-in-rails-6-f168a9f09a1f) requirements, the service classes are namespaced under the controller itself. For example, `/app/controller_services/games_controller/update_service.rb` contains a class called `GamesController::UpdateService`.

The service class is instantiated with exactly the data it needs to figure out what kind of response to make (i.e., status code) and what the payload should be. It has a single instance method, `perform`, that identifies the correct type of response and returns a result object with the response type and payload.

## The Result Object

Results objects live in the `/lib/service` directory. There is a base `Service::Result` class that serves as a parent class to the subclasses used by the service classes. Each result object defines a `status` method that is set to a symbol representing an HTTP status, such as `:no_content` or `:unprocessable_entity`. Any result object can be instantiated with a `:resource` or `:errors`. A `:resource` is any JSON string, array, or object (represented using Ruby data structures). Errors are an array of strings describing the errors that occurred. If a result object does not have a `:resource` or `:errors` object defined, the response will include no data (i.e., will call `head` instead of `render` on the controller).

Existing result classes are:

* `Service::OkResult`
* `Service::CreatedResult`
* `Service::NoContentResult`
* `Service::UnauthorizedResult`
* `Service::NotFoundResult`
* `Service::MethodNotAllowedResult`
* `Service::UnprocessableEntityResult`
* `Service::InternalServerErrorResult`

An example of their use might be (inside a controller service's `#perform` method):
```ruby
def perform
  return Service::NotFoundResult.new(errors: ['Could not find wish list']) unless wish_list.present?
end
```

## The Response Object

The `Controller::Response` object lives in the `/lib/controller` directory. The response takes a controller and a result object as an argument and makes the response indicated in the result object using the controller passed in. This usually happens in the controller itself:

```ruby
# /app/controllers/wish_lists_controller.rb

require 'controller/response'

class WishListsController < ApplicationController
  def create
    # The CreateService needs to know who to create a list for and what
    # params to do it with. If successful, it will return a
    # Service::CreatedResponse object.
    result = CreateService.new(current_user, wish_list_params).perform

    # Renders the right JSON response and status code
    response = ::Controller::Response.new(self, result).execute
  end
end
```

## Standardised Responses

Now, all error responses from the API, if they have body content, will return a JSON object with a single key, `"errors"`, and a list of error messages. There is now an `#error_array` method defined on `ApplicationRecord` that assembles normal ActiveRecord validation errors into such an array.
