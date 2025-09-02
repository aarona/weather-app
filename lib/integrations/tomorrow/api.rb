module Integrations
  module Tomorrow
    class Api
      include HTTParty

      FORECAST_TIMESTEPS = "1d".freeze

      base_uri "https://api.tomorrow.io/v4"

      def initialize(location:)
        @location = location
        @apikey = ENV.fetch("TOMORROW_API_KEY")
      end

      def current_conditions
        response = self.class.get("/weather/realtime", query: { location:, apikey: })

        if response.ok? && response.parsed_response.is_a?(Hash)
          location = response.dig("location")
          values = response.dig("data", "values")
          time = response.dig("data", "time")

          { location:, values:, time: }
        else
          raise_error_from_response!(response)
        end
      end

      def forecast
        response = self.class.get("/weather/forecast", query: {
          location:,
          timesteps: FORECAST_TIMESTEPS,
          apikey:
        })

        if response.ok? && response.parsed_response.is_a?(Hash)
          response.parsed_response.dig("timelines", "daily").map do |day|
            values = day["values"]
            time = day["time"]

            { values:, time: }
          end

        else
          raise_error_from_response!(response)
        end
      end

      private

      attr_accessor :location, :apikey

      def raise_error_from_response!(response)
        error_message = response&.[]("message") || "An unknown error occurred"

        # Normally, I would not handle an Authentication error like this
        # but this is a reminder that you may need to create your own API Key
        # and set it in the .env file.
        raise AuthenticationError.new("Check that the API Key has been set") if response.code == 401

        if response.code >= 400
          if error_message =~ /location/
            raise ClientError.new("Unable to find the location")
          else
            raise ClientError.new(error_message)
          end
        elsif response.code >= 500
          raise ServerError.new(error_message)
        else
          raise StandardError.new(error_message)
        end
      end
    end
  end
end
