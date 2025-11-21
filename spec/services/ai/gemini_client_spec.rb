require "rails_helper"

RSpec.describe Ai::GeminiClient do
  let(:api_key) { "test-key" }
  let(:model)   { "gemini-test-model" }
  let(:endpoint) { "https://fake-gemini.com/v1beta" }

  subject(:client) do
    described_class.new(api_key: api_key, model: model, api_endpoint: endpoint)
  end



  # ------------------------------
  # Net::HTTP Mock Helper
  # ------------------------------
  def mock_http_with(response_body:, code: "200")
    http_double = instance_double(Net::HTTP)
    request_double = instance_double(Net::HTTP::Post)

    allow(Net::HTTP).to receive(:new).and_return(http_double)

    allow(Net::HTTP::Post).to receive(:new).and_return(request_double)
    allow(request_double).to receive(:[]=)
    allow(request_double).to receive(:body=)

    response = instance_double(Net::HTTPSuccess, body: response_body, code: code)

    if code == "200"
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    else
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
    end

    allow(http_double).to receive(:use_ssl=)
    allow(http_double).to receive(:read_timeout=)
    allow(http_double).to receive(:verify_mode=)
    allow(http_double).to receive(:request).and_return(response)
  end

  # ------------------------------
  # SUCCESS CASE
  # ------------------------------
  describe "#generate_gift_ideas success" do
    it "returns gift_ideas array from valid JSON" do
      gemini_reply = {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                { "text" => { "gift_ideas" => [{ "title" => "Book", "description" => "Nice gift" }] }.to_json }
              ]
            }
          }
        ]
      }.to_json

      mock_http_with(response_body: gemini_reply)

      ideas = client.generate_gift_ideas("test prompt")
      expect(ideas.first["title"]).to eq("Book")
    end

    it "supports fallback key: ideas" do
      gemini_reply = {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                { "text" => { "ideas" => [{ "title" => "Pen" }] }.to_json }
              ]
            }
          }
        ]
      }.to_json

      mock_http_with(response_body: gemini_reply)

      ideas = client.generate_gift_ideas("test")
      expect(ideas.first["title"]).to eq("Pen")
    end

    it "supports fallback key: data" do
      gemini_reply = {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                { "text" => { "data" => [{ "title" => "Watch" }] }.to_json }
              ]
            }
          }
        ]
      }.to_json

      mock_http_with(response_body: gemini_reply)

      ideas = client.generate_gift_ideas("test")
      expect(ideas.first["title"]).to eq("Watch")
    end

    it "supports top-level array" do
      gemini_reply = {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                { "text" => [{ "title" => "Shoes" }].to_json }
              ]
            }
          }
        ]
      }.to_json

      mock_http_with(response_body: gemini_reply)

      ideas = client.generate_gift_ideas("test")
      expect(ideas.first["title"]).to eq("Shoes")
    end
  end

  # ------------------------------
  # ERROR CASES
  # ------------------------------
  describe "#generate_gift_ideas errors" do
    it "raises on HTTP error" do
      mock_http_with(response_body: "bad", code: "500")
      expect {
        client.generate_gift_ideas("test")
      }.to raise_error(Ai::GeminiClient::Error, /Gemini HTTP error/)
    end

    it "raises when candidates missing" do
      reply = { "other" => [] }.to_json
      mock_http_with(response_body: reply)

      expect {
        client.generate_gift_ideas("test")
      }.to raise_error(Ai::GeminiClient::Error, /no candidates/)
    end

    it "raises when text part missing" do
      reply = {
        "candidates" => [
          { "content" => { "parts" => [] } }
        ]
      }.to_json

      mock_http_with(response_body: reply)

      expect {
        client.generate_gift_ideas("test")
      }.to raise_error(Ai::GeminiClient::Error, /no text parts/)
    end

    it "raises for invalid JSON" do
      reply = {
        "candidates" => [
          {
            "content" => {
              "parts" => [{ "text" => "INVALID_JSON{" }]
            }
          }
        ]
      }.to_json

      mock_http_with(response_body: reply)

      expect {
        client.generate_gift_ideas("test")
      }.to raise_error(Ai::GeminiClient::Error, /Failed to parse/)
    end

    it "raises for unexpected structure" do
      reply = {
        "candidates" => [
          {
            "content" => { "parts" => [{ "text" => { "wrong" => 123 }.to_json }] }
          }
        ]
      }.to_json

      mock_http_with(response_body: reply)

      expect {
        client.generate_gift_ideas("x")
      }.to raise_error(Ai::GeminiClient::Error, /Unexpected JSON structure/)
    end
  end
end
