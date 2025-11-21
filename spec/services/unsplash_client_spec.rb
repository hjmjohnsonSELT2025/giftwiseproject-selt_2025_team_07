require "rails_helper"

RSpec.describe UnsplashClient do
  let(:access_key) { "dummy-key" }
  let(:api_base)   { "https://api.unsplash.test" }

  subject(:client) do
    described_class.new(access_key: access_key, api_base: api_base)
  end

  describe "#initialize" do
    it "raises an error if access key is missing" do
      expect {
        described_class.new(access_key: nil)
      }.to raise_error(UnsplashClient::Error, /missing/)
    end
  end

  # ==========================================================
  # Helper to mock Net::HTTP
  # ==========================================================
  def mock_http(response_body:, code: "200")
    http_double    = instance_double(Net::HTTP)
    request_double = instance_double(Net::HTTP::Get)
    response_double = instance_double(Net::HTTPResponse, body: response_body, code: code)

    # HTTP success check
    if code == "200"
      allow(response_double).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    else
      allow(response_double).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
    end

    # setup
    allow(Net::HTTP).to receive(:new).and_return(http_double)
    allow(Net::HTTP::Get).to receive(:new).and_return(request_double)

    allow(request_double).to receive(:[]=)  # Authorization header
    allow(http_double).to receive(:use_ssl=)
    allow(http_double).to receive(:verify_mode=)
    allow(http_double).to receive(:request).and_return(response_double)
  end

  # ==========================================================
  # Main method tests
  # ==========================================================
  describe "#search_image" do
    it "returns nil when query is blank" do
      expect(client.search_image("")).to eq(nil)
      expect(client.search_image(nil)).to eq(nil)
    end

    it "returns nil when HTTP response is not successful" do
      mock_http(response_body: "{}", code: "500")
      expect(client.search_image("flowers")).to eq(nil)
    end

    it "returns nil when JSON has no results" do
      body = { "results" => [] }.to_json
      mock_http(response_body: body)

      expect(client.search_image("mountain")).to eq(nil)
    end

    it "returns small URL if available" do
      body = {
        "results" => [
          { "urls" => { "small" => "small.jpg", "regular" => "regular.jpg" } }
        ]
      }.to_json

      mock_http(response_body: body)

      expect(client.search_image("cat")).to eq("small.jpg")
    end

    it "falls back to regular URL when small is missing" do
      body = {
        "results" => [
          { "urls" => { "regular" => "regular.jpg" } }
        ]
      }.to_json

      mock_http(response_body: body)

      expect(client.search_image("dog")).to eq("regular.jpg")
    end

    it "returns nil if JSON parsing fails" do
      bad_json = "{bad json"
      mock_http(response_body: bad_json)

      expect(client.search_image("car")).to eq(nil)
    end
  end
end
