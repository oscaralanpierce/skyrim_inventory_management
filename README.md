# Skyrim Inventory Management API

[Skyrim Inventory Management](https://sim.oscaralanpierce.com) is a fully featured, split-stack Rails/React app enabling users to manage inventory and tasks across multiple properties in Skyrim. The backend API found in this repo is hosted on [Render](https://render.com) at https://sim-api.oscaralanpierce.com.

## Disclaimer

This application is my hobby project intended for my personal use and all other users should use at their own risk. There are no admin users who can fix anything you break about your own account or data, so if you fuck something up, consider it fucked. I do have certain access to data on account of being able to access the logs and database directly through Heroku, but don't count on my help for anything because (1) I can't guarantee I can do anything about your specific problem and (2) I don't have the bandwidth or executive function to consistently and promptly act in a support capacity on this app for other users. I'll help if I can because I'm not an asshole but I'm not making any promises. In particular, note that I do not keep backup data, nor does this app do [soft deletes](https://www.dailysmarty.com/posts/how-to-soft-delete-in-rails). Any data you delete is gone forever.

## Authentication

Skyrim Inventory Management uses [Sign In With Google](https://developers.google.com/identity/sign-in/web/sign-in) to handle authentication. This is implemented using [Firebase](https://firebase.google.com). The front end signs in users and receives access tokens from Google. When the front end requests data from the back end, it includes these tokens as [bearer tokens](https://oauth.net/2/bearer-tokens/#:~:text=Bearer%20Tokens%20are%20the%20predominant,such%20as%20JSON%20Web%20Tokens.) in the `"Authorization"` header of each request. The back end then validates these tokens by contacting Google's API and including the app's Firebase credentials (stored as Rails credentials). The token is verified in a `before_action` defined on the `ApplicationController`, and a 401 response is sent from that `before_action` if the response indicates the token is invalid or the response body has an unexpected shape. Specifically, the response body from Google is expected to be a JSON object containing a `"users"` key with an array of objects. If this array is empty, absent, or contains more than one user, a `401 Unauthorized` response is returned to the front end.

Users are uniquely identified by the UID of the Google account they use to sign in. This value corresponds to the `"localId"` key of the user object returned from the token validation endpoint. On authentication, the user's account will be updated with any other information in the response, for example, if their email address, display name, or photo URL have changed. If the same user logs in with another UID for some reason, a new account will be created for them. There is no way to intelligently link accounts with different UIDs based on email or other profile data.

### Authenticating Resources

All resources are scoped to the currently authenticated user. Requesting a resource that doesn't belong to the authenticated user will result in a 404, not a 401. So, if User 1 owns the `WishList` with ID 24, requesting `/wish_lists/24` with a valid token belonging to User 2 will simply result in the resource not being found, and not in a 401 response. All requests lacking a valid token will return 401 responses.

## Resources

### Users

All resources are scoped to the user authenticated during a given request. Profile information for users is automatically updated with data returned from Google on token verification. The profile stores only the user's name, email, and profile image URL from Google. Of these, email is king: a user's email cannot be changed and if, for some reason, Google returns a different email, a new user account will be created with no association to the original one. The user's `uid` is also set to their email.

There are no admin users or other special user accounts and thus no way to view data for users other than the one authenticated in the current request.

#### Schema

```
id: integer, primary key, unique, not null
uid: string, unique, not null
email: string, unique, not null, generally equal to `uid`
photo_url: string or null
display_name: string or null
```

### RESTful Resources

See the [API docs](/docs/api/README.md) for information about resources like games, wish lists, and more. For information about models not exposed as RESTful resources, see docs on [canonical models](/docs/canonical_models/README.md).

## Developer Info

### Local Setup

The Skyrim Inventory Management API is a basic Rails API running on Rails 8 and Ruby 4. You can set it up locally by cloning the repository, `cd`ing into it, and running:
```bash
./script/setup.sh
```
The setup script installs dependencies (including Bundler), sets up the database, and populates [canonical models](/docs/canonical-models.md), including alchemical properties, enchantments, and spells.

Note that the setup script installs a Git pre-commit hook that runs [Rubocop](#rubocop). **Running the setup script will overwrite any existing precommit hooks you have in the repo.** Since these are not saved in Git, they are not recoverable if you overwrite them (unless you've committed them to Git somewhere outside this repo).

To run the server, simply run `bundle exec rails s` and your server will start on `localhost:3000`.

Note that if you are also running the [SIM front end](https://github.com/danascheider/skyrim_inventory_management_frontend), it will expect the backend to run on `localhost:3000` in development. CORS settings on the API require the front end to run on `localhost:5173`.

### Testing

The SIM API is tested using [RSpec](https://github.com/rspec/rspec) with [FactoryBot](https://github.com/thoughtbot/factory_bot_rails) for factories. Run specs on the command line using:
```bash
bundle exec rails spec
```
If you'd like to run only a specific subset of specs, these options are the way to go:
```bash
# runs only one directory of specs
bundle exec rspec spec/models

# runs only one spec file
bundle exec rspec spec/requests/wish_lists_spec.rb

# runs a specific spec on line 42 of the specified file
bundle exec rspec spec/models/wish_list_item_spec.rb:42
```

All pull requests should include whatever test updates are required to ensure the new code is thoroughly covered by quality, passing tests.

#### Testing Timestamps

One caveat in testing is that timestamps may be treated differently in [GitHub Actions](#ci) than they are in your development environment. Specifically, the last four digits of timestamps are truncated in the GitHub Actions environment. That means that you will not be able to use the `eq` matcher for timestamp tests, even with Timecop. Instead, you should use the `be_within` timestamp, using Timecop and keeping the tolerance as small as possible (0.005 seconds is usually plenty):
```ruby
t = Time.zone.now + 3.days
Timecop.freeze(t) do
  perform
  expect(wish_list.reload.updated_at).to be_within(0.005.seconds).of(t)
end
```

### Rubocop

SIM uses [Rubocop](https://github.com/rubocop/rubocop) for linting and style purposes. The [rubocop-rails](https://github.com/rubocop/rubocop-rails), [rubocop-rspec](https://github.com/rubocop/rubocop-rspec), and [rubocop-performance](https://github.com/rubocop/rubocop-performance) plugins are also used to add additional relevant cops. We are restrictive in which cops we enable and all are disabled by default. The rule for disabling cops is three broken builds without meaningful changes and we disable the cop by removing it from the `.rubocop.yml` file. We strongly avoid `rubocop:disable` comments in the code.

When you run the setup script, it installs a precommit hook that runs Rubocop against any changed Ruby files. This hook can be skipped with `--no-verify` if you absolutely need to commit something that breaks Rubocop, although you should be aware that Rubocop also runs in [CI](#ci). Additionally, if you would rather run Rubocop manually, you can run `rm .git/hooks/pre-commit` to remove the hook.

#### Running Rubocop Manually

The precommit hook can be very annoying since it doesn't autocorrect and prevents the commit if there are any failures. For that reason, it's best to run Rubocop prior to attempting a commit. There are two ways to do this in SIM. The most basic, built-in way is:
```sh
bundle exec rails rubocop:auto_correct
```
Unfortunately, this runs against every file in the repo, not just changed files, and it can take some time to get through them all. For that reason, we've created a [script](/script/run_rubocop.sh) that runs Rubocop, with autocorrect, only against files that are _staged_ (not just changed) in Git. The reason it only runs against staged files is that running it against changed files (`git diff`) would not catch any untracked files (those that have not been previously committed to Git). You can run the script from the root directory of the repo as follows:
```sh
git add file1.rb file2.rb
./script/run_rubocop.sh
```
The `run_rubocop.sh` script runs Rubocop against the same files that will be checked in the pre-commit hook, so if Rubocop passes when running the script, you won't have any issues committing.

### Workflows

We use [Trello](https://trello.com/b/Jo7Z3oUh/sim-project-board) to track work for both SIM applications. To work on an issue, first check out a branch for your dev work and do the work on that branch. Push to GitHub and open a pull request. The pull request should link to the Trello card as well as providing context, a summary of changes, and an explanation for any design choices you made or anything that might not make sense to a reviewer or future developer looking at Git history. Link to the PR in the Trello card and move the card to reviewing. Once your PR has been approved and CI has passed, you are free to merge.

### CI

Rubocop and RSpec are run against all pull requests using [GitHub Actions](https://github.com/features/actions). Pull requests may not be merged if the build is broken. CI also runs any time changes are pushed or merged to `main`. [Render](https://render.com) automatically deploys on merge to main after checks have passed.

### Deployment

The Skyrim Inventory Management API is deployed to [Render](https://render.com). Deployments are done automatically when `main` is merged, after CI passes. Monitor the deploy via the Render dashboard and test in production when it is finished to ensure no breakage has been introduced. The `render` command line tool can be used to view logs, manage deploys, restart services, or use SSH or psql locally. Use `render restart` after updating initializers.

### Troubleshooting in Production

Use the Render dashboard and command line tool to troubleshoot production deploys.

#### Viewing Logs

You can view logs with the Render CLI using:

```
render logs
```

You will be prompted to select a service.

#### Using the Rails Console

You can use the production Rails console from your development machine by SSHing into the production instance using:

```
render ssh
```

Once you are into the production box, run:

```
rails console
```
