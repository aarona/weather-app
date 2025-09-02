# Weather API Integration (with Tomorrow.io)

## Setup Process

### Acquire a FREE Tomorrow.io API Key

The API I chose to integrate with is from the site [tomorrow.io](https://app.tomorrow.io). For security purposes, I've left out my own API Key from the repository so you'll need to get one for yourself if you don't already have one. You can [create an account](https://app.tomorrow.io/signup) to get one and they are free.

### Setup your environment

Once you've obtained your API key from Tomorrow, you'll need to copy or rename `.env.example` to `.env` and set the `TOMORROW_API_KEY` to your API key. You'll need to obtain the `config/master.key` for the credentials file. I can provide this through the recruiter.

An alternative is to just recreate the credentials file:

```bash
rm config/credentials.yml.enc
bundle exec rails credentials:edit
```

## Running the application

If you want to run the application locally, you can run the following command:

```bash
bin/setup
```

### Deploying the application

If you have Docker installed, you can test the deployment process locally by running the following command:

```bash
bin/local-deploy
```

After a successful deployment:

- Application will be available at: http://localhost:3000
- Container name: `weather_app-web`
- Port mapping: 3000 (host) -> 80 (container)
- Persistent storage: Docker volume `weather_app_storage`

### Clean up

To clean up the container you can run this command:

```bash
docker stop weather_app-web && docker rm weather_app-web
```
## Technical Documentation (Decomposition)

I like to write my RSpec tests in such a way that it can be documentation for the class its describing. Review the tests to get a good understand of how the system works but a quick rundown on all the moving parts, I've documented them here based on the four layers of the system from top to bottom:

### Views/Helpers/Controller

- `WeatherHelper` has some formatting/conversion methods

- There is one index view with some components
  - Current conditions view component
  - Daily forecast component
  - Error message component
  - Form component

- `WeatherController` has two actions: `index` and `update`. Index just renders the initial search form and the update action leverages Turboframes to render/rerender the current weather data in place instead of doing full page loads.

### Service Objects

- `WeatherRetriever` has one public method `retrieve` which does a cache look up based on the zip code submitted and either calls the API or returns the cached value. It then wraps the results in typed objects before returning them.

### API Integration

I like to put all my API integration code under the `lib/integrations/(API name as namespace)` directory. Even though, only one API is involved I still did this as personal choice.

#### Data Wrapper Classes

- `Integrations::Tomorrow::CurrentConditions`
  - `time`: The time the conditions were captured
  - `location`: A hash of location data including longitude/latitude
  - `temperature`: The current temp
  - `feels_like`: What the API says the "apparent" temperature is.

- `Integrations::Tomorrow::DailyForecast`
  - `time`: The day the conditions are being predicted for
  - `temperature_high`: The predicted high for the day
  - `temperature_low`: The predicted low for the day
  - `temperature_average`: The recorded average temp for the day

#### Api Error Exception Classes

`Integrations::AuthenticationError`, `Integrations::ClientError` and `Integrations::ServerError` are simple classes that allow for differentiation of error types from the API.

#### Api Class

The `Integrations::Tomorrow::Api` class implements `HTTParty` methods to make requests to Tomorrow.io's API. It returns raw JSON hashes.

- `current_conditions`: Returns a hash with three items:
  - `time`: The time that the conditions were recorded
  - `values`: The set of numeric values that range anywhere from humidity to temperature
  - `location`: Location data including lon/lat, a label for the location queried and how the location was queried by.

- `forecast`: Returns an array of daily forecast data. Each item has the following
  - `time`: The day of the predicted forecast
  - `values`: The set of numeric values that include high/low/average predicted temperatures

## Considerations

### Scalability

Because I wanted to keep the dependencies as small as possible, I leveraged [Rails' Solid Cache](https://github.com/rails/solid_cache). If this application would need to scale above a simple monolith or would require multiple instances of the application running behind a Gateway API/Load balancer, the application would need to migrate from Solid Cache to using Redis so the cache is in a central location.

### Address requirement

Despite an address being required as input but no requirements to save any of it but the zip code for caching purposes, I threw away the street address input after the form submission and only keep the city, state and zip code for querying the API and for caching.
