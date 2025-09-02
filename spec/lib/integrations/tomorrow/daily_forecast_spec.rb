describe Integrations::Tomorrow::DailyForecast do
  subject { described_class.new(values:, time:) }

  # More values are returned from the API but only need to mock these
  let(:values) do
    {
      "temperatureAvg" => temperature_average,
      "temperatureMax" => temperature_high,
      "temperatureMin" => temperature_low
    }
  end

  let(:temperature_high) { 37.4 }
  let(:temperature_low) { 28.6 }
  let(:temperature_average) { 28.6 }
  let(:time) { "2025-08-31T03:45:00Z" }

  describe '#temperature_high' do
    it { expect(subject.temperature_high).to eq temperature_high }
  end

  describe '#temperature_low' do
    it { expect(subject.temperature_low).to eq temperature_low }
  end

  describe '#temperature_average' do
    it { expect(subject.temperature_average).to eq temperature_average }
  end

  describe '#time' do
    it { expect(subject.time).to eq Date.parse(time) }
  end
end
