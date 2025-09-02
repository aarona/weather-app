module Integrations
  module Tomorrow
    class CurrentConditions
      attr_accessor :time, :location

      def initialize(location:, values:, time: Time.zone.now.to_s)
        @time = DateTime.parse(time)
        @values = values
        @location = location
      end

      def temperature = @temperature ||= values["temperature"]
      def feels_like = @feels_like ||= values["temperatureApparent"]

      private

      attr_accessor :values
    end
  end
end
