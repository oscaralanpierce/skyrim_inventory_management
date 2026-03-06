# 0005. Switch from Heroku to Render

## Date

2026-03-07

## Approved By

@oscaralanpierce

## Decision

We will migrate the SIM backend from hosting on Heroku to Render.

[Heroku](https://heroku.com) is in maintenance mode with Salesforce, so it's necessary to find another PaaS hosting option. The two most similar options are [Railway](https://railway.com) and [Render](https://render.com). Of these, Render is the better option for SIM due to its mature Ruby build tooling and native support for the `release` key in the Procfile.

## Glossary

* **Heroku:** The hosting platform we are currently using for the SIM back end.
* **Platform as a Service (PaaS):** A service that provides hosted infrastructure, enabling simple deployment of backend/dynamic applications
* **Railway:** A platform as a service (PaaS) that can act as an alternative to Heroku.
* **Render:** A platform as a service (PaaS) that can act as an alternative to Heroku.

## Context

We are currently hosting the SIM API on Heroku, which is owned by Salesforce. Salesforce has placed Heroku in maintenance mode, so it makes sense to consider other deployment options. The two most promising options are Railway and Render.

## Considerations

The most important consideration was the infrastructure needs of the SIM application. The architecture is simple and there is no load, so most PaaS services would offer the fundamentals we need.

### Availability of Pre-Deploy Tasks

In Heroku, migrations are run before traffic is switched to a new deployed version of the app using the `releases` key of the Procfile. Whereas Render also supports this natively, Railway doesn't have as elegant a solution and would require some manual tooling to make sure migrations are run before traffic is switched.

### Cost and Pricing Model

Railway charges a low base price per service with added fees for usage, whereas Render charges a flat fee per service. This makes Render a cheaper choice for high volume services, but since SIM is not high volume, Railway would likely be cheaper for us. Still, at our scale, the difference would only be a few dollars a month.

### Migration Difficulty

Render is more similar to Heroku and, for that reason, switching from Heroku to Render would require less work than moving to Railway.

### Quality of Ruby Tooling

Adequate Ruby tooling is available for both Railway and Render, however, Render's Ruby buildpack is directly Heroku-compatible.

## Summary

Despite a modestly higher cost, Render makes the most sense to use for SIM due to its improved handling of Rails apps.
