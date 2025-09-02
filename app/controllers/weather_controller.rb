class WeatherController < ApplicationController
  rescue_from StandardError, with: :unknown_error
  rescue_from Integrations::AuthenticationError, with: :client_error
  rescue_from Integrations::ClientError, with: :client_error
  rescue_from Integrations::ServerError, with: :server_error

  def index; end

  def update
    validate_input!

    results = WeatherRetriever.new(
      city: form_params[:city],
      state: form_params[:state],
      zip_code: form_params[:zip_code]
    ).retrieve

    @current_weather = results[:current_conditions]
    @forecast = results[:forecast]
    @cached = results[:cached]

    render turbo_stream: [
      turbo_stream.update("error-message", partial: "error", locals: { error: nil }),
      turbo_stream.update("current-weather",
                            partial: "current_conditions",
                            locals: {
                              current_weather: @current_weather,
                              todays_forecast: @forecast.first,
                              cached: @cached
                            }),
      turbo_stream.update("daily-forecast", partial: "daily_forecast", locals: { forecast: @forecast })
    ]
  end

  private

  def client_error(e)
    Rails.logger.error "A ClientError occurred: #{e.message}"

    render turbo_stream: [
      turbo_stream.update("error-message", partial: "error", locals: { error: e.message })
    ]
  end

  def server_error(e)
    Rails.logger.error "An API Error occurred: #{e.message}"

    render turbo_stream: [
      turbo_stream.update("error-message", partial: "error", locals: { error: e.message })
    ]
  end

  def unknown_error(e)
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")

    render turbo_stream: [
      turbo_stream.update("error-message", partial: "error", locals: { error: "An unknown error occurred" })
    ]
  end

  def form_params
    # Required params lie in the root of the hash and must
    # be sliced first to avoid "Unpermitted params" log.
    @form_params ||=
    params.slice(:city, :state, :zip_code)
          .permit(:city, :state, :zip_code)
  end

  def validate_input!
    raise Integrations::ClientError.new("Invalid Zip Code") unless form_params[:zip_code] =~ /^\d{5}$/
  end
end
