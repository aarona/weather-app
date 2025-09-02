describe Integrations::Tomorrow::Api do
  subject { described_class.new(location:) }

  let(:location) { '95973' }

  describe '#current_conditions' do
    context 'when the location is valid' do
      it 'should return a current conditions object' do
        VCR.use_cassette('tomorrow/current-conditions/valid-location') do
          result = subject.current_conditions

          expect(result).to be_an_instance_of(Hash)
          expect(result[:location]).to eq({
              "lat" => 39.7662239074707,
              "lon" => -121.85606384277344,
              "name" => "Chico, Butte County, California, 95973, United States",
              "type" => "postcode"
            })

          expect(result[:values]).to include({
              "temperature" => 31.2,
              "temperatureApparent" => 30.7
            })

          expect(result[:time]).to eq "2025-08-31T03:45:00Z"
        end
      end
    end

    context 'when the location is invalid' do
      let(:location) { 'Anywhereville, USA' }

      it 'should raise an error' do
        VCR.use_cassette('tomorrow/current-conditions/invalid-location') do
          expect { subject.current_conditions }.to raise_error Integrations::ClientError, "Unable to find the location"
        end
      end
    end
  end

  describe '#forecast' do
    context 'when the location is valid' do
      it 'should return an array of forecast objects' do
        VCR.use_cassette('tomorrow/forecast/valid-location') do
          result = subject.forecast

          expect(result).to be_an_instance_of(Array)
          expect(result[0]).to be_an_instance_of(Hash)
          expect(result[0][:values]).to include({
            "temperatureAvg" => 28.6,
            "temperatureMax" => 37.4,
            "temperatureMin" => 18.1
          })

          expect(result[0][:time]).to eq "2025-08-30T13:00:00Z"
        end
      end
    end

    context 'when the location is invalid' do
      let(:location) { 'Anywhereville, USA' }

      it 'should raise an error' do
        VCR.use_cassette('tomorrow/forecast/invalid-location') do
          expect { subject.forecast }.to raise_error Integrations::ClientError, "Unable to find the location"
        end
      end
    end
  end

  context 'when an invalid API Key is used' do
    before do
      allow(ENV).to receive(:fetch).with('TOMORROW_API_KEY').and_return('invalid-api-key')
    end

    it 'should raise an authentication error' do
      VCR.use_cassette('tomorrow/invalid-api-key') do
        expect { subject.current_conditions }.to raise_error Integrations::AuthenticationError, "Check that the API Key has been set"
      end
    end
  end
end
