describe WeatherRetriever do
  subject { described_class.new(city:, state:, zip_code:) }

  let(:zip_code) { '95973' }
  let(:city) { 'Chico' }
  let(:state) { 'CA' }
  let(:store) { ActiveSupport::Cache.lookup_store(:memory_store) }
  let(:api) { Integrations::Tomorrow::Api.new(location: zip_code) }

  before do
    allow(Rails).to receive(:cache).and_return(store)
    allow(Integrations::Tomorrow::Api).to receive(:new).and_return(api)

    Rails.cache.clear
  end

  describe '#retrieve' do
    it 'should return typed data' do
      VCR.use_cassette('tomorrow/current-conditions/valid-location') do
        VCR.use_cassette('tomorrow/forecast/valid-location') do
          result = subject.retrieve

          expect(result[:current_conditions]).to be_an_instance_of(Integrations::Tomorrow::CurrentConditions)
          expect(result[:forecast]).to be_an_instance_of(Array)
          expect(result[:forecast][0]).to be_an_instance_of(Integrations::Tomorrow::DailyForecast)
        end
      end
    end

    context 'when the zip code has not yet been cached' do
      it 'should call the API' do
        VCR.use_cassette('tomorrow/current-conditions/valid-location') do
          VCR.use_cassette('tomorrow/forecast/valid-location') do
            expect(api).to receive(:current_conditions).once.and_call_original
            expect(api).to receive(:forecast).once.and_call_original

            subject.retrieve
          end
        end
      end

      it 'should indicate that the data returned was not cached data' do
        VCR.use_cassette('tomorrow/current-conditions/valid-location') do
          VCR.use_cassette('tomorrow/forecast/valid-location') do
            expect(Rails.cache.exist?(zip_code)).to be_falsey

            result = subject.retrieve

            expect(result[:cached]).to eq false
            expect(Rails.cache.exist?(zip_code)).to be_truthy
          end
        end
      end
    end

    context 'when the zip code has been cached' do
      let(:time) { "2025-08-31T03:45:00Z" }

      # Just the values currently supported are enough
      let(:values) { { "temperature" => 31.2, "temperatureApparent" => 30.7 } }
      let(:location) do
        {
          "lat" => 39.7662239074707,
          "lon" => -121.85606384277344,
          "name" => "Chico, Butte County, California, 95973, United States",
          "type" => "postcode"
        }
      end

      # Just passing the current supported values
      let(:forecast) do
        [
          {
            values: {
              "temperatureAvg" => 28.6,
              "temperatureMax" => 37.4,
              "temperatureMin" => 18.1
            },
            time: "2025-08-30T13:00:00Z"
          },
          {
            values: {
              "temperatureAvg" => 29.8,
              "temperatureMax" => 38.5,
              "temperatureMin" => 20.2
            },
            time: "2025-08-31T13:00:00Z"
          }
        ]
      end

      let(:cached_data) do
        {
          current_conditions: { location:, values:, time: },
          forecast:
        }
      end

      before do
        Rails.cache.write(zip_code, cached_data)
      end

      it 'should call the API' do
        expect(api).to_not receive(:current_conditions)
        expect(api).to_not receive(:forecast)

        subject.retrieve
      end

      it 'should indicate that the data returned was not cached data' do
        result = subject.retrieve

        expect(result[:cached]).to eq true
      end
    end
  end
end
