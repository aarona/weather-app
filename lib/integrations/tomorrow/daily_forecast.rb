module Integrations
  module Tomorrow
    class DailyForecast
      attr_accessor :time

      def initialize(values:, time: Time.zone.today.to_s)
        @values = values
        @time = Date.parse(time)
      end

      def temperature_high = @temperature_high ||= values["temperatureMax"]
      def temperature_low = @temperature_low ||= values["temperatureMin"]
      def temperature_average = @temperature_average ||= values["temperatureAvg"]

      private

      attr_accessor :values
    end
  end
end
