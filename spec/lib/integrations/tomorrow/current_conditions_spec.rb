describe Integrations::Tomorrow::CurrentConditions do
  subject { described_class.new(location:, values:, time:) }

  let(:location) do
    {
      "lat" => 38.58285903930664,
      "lon" => -121.49198913574219,
      "name" => "Downtown, Sacramento, Sacramento County, California, 95814, United States",
      "type" => "postcode"
    }
  end

  # More values are returned from the API but only need to mock these
  let(:values) do
    {
     "temperature" => temperature,
     "temperatureApparent" => feels_like
    }
  end

  let(:temperature) { 31.2 }
  let(:feels_like) { 30.7 }
  let(:time) { "2025-08-31T03:45:00Z" }

  describe '#temperature' do
    it { expect(subject.temperature).to eq temperature }
  end

  describe '#feels_like' do
    it { expect(subject.feels_like).to eq feels_like }
  end

  describe '#time' do
    it { expect(subject.time).to eq DateTime.parse(time) }
  end
end
