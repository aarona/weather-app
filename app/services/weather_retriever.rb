class WeatherRetriever
  EXPIRY_LENGTH = 30.minutes

  def initialize(city:, state:, zip_code:)
    @city = city
    @state = state
    @zip_code = zip_code
  end

  def retrieve
    cached = true

    results = Rails.cache.fetch(zip_code, expires_in: EXPIRY_LENGTH) do
      Rails.logger.info "CACHE MISS! Calling Weather API"
      Rails.logger.info "Looking up location: #{location}"

      cached = false
      api = Integrations::Tomorrow::Api.new(location:)
      current_conditions = api.current_conditions
      forecast = api.forecast

      { current_conditions:, forecast: }
    end

    Rails.logger.info "CACHE HIT! For zip code: #{zip_code}" if cached

    results.merge!({ cached: })
    results[:current_conditions] = Integrations::Tomorrow::CurrentConditions.new(**results[:current_conditions])
    results[:forecast] = results[:forecast].map { |day| Integrations::Tomorrow::DailyForecast.new(**day) }
    results
  end

  private

  attr_accessor :city, :state, :zip_code

  def location = @location ||= "#{city} #{state} #{zip_code}"
end
