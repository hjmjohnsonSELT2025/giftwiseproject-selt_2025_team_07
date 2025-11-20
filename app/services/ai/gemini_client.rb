# app/services/ai/gemini_client.rb
require "net/http"
require "uri"
require "json"
require "openssl"

module Ai
  class GeminiClient
    class Error < StandardError; end

    def initialize(api_key: nil, model: nil, api_endpoint: nil)
      creds = Rails.application.credentials

      @api_key      = api_key      || creds.dig(:gemini, :api_key)
      @model        = model        || creds.dig(:gemini, :model)        || "gemini-2.0-flash-lite-001"
      @api_endpoint = api_endpoint || creds.dig(:gemini, :api_endpoint) || "https://generativelanguage.googleapis.com/v1beta"

      raise Error, "Gemini API key missing" if @api_key.blank?
    end

    # Returns an array of idea hashes:
    # [{ "title" => "...", "description" => "...", ... }, ...]
    def generate_gift_ideas(prompt)
      uri = URI.parse("#{@api_endpoint}/models/#{@model}:generateContent?key=#{@api_key}")

      # Wrap the user prompt in a stricter JSON-only instruction
      full_prompt = <<~PROMPT
        You are a JSON-only API. Respond ONLY with valid JSON, no markdown or explanations.

        Return a JSON object with this exact top-level structure:

        {
          "gift_ideas": [
            {
              "title": "Short title string",
              "description": "Short description string"
            }
          ]
        }

        Requirements:
        - "gift_ideas" must always be present.
        - It must be an array, even if there is only one idea.
        - Do not include any other top-level keys.

        User request:
        #{prompt}
      PROMPT

      request_body = {
        contents: [
          {
            role: "user",
            parts: [{ text: full_prompt }]
          }
        ],
        generationConfig: {
          # Ask explicitly for JSON
          responseMimeType: "application/json"
        }
      }

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.read_timeout = 30

      if Rails.env.development? || Rails.env.test?
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request.body = JSON.dump(request_body)

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "Gemini HTTP error: #{response.code} #{response.body}"
      end

      parsed = JSON.parse(response.body)
      json_text = extract_json_text(parsed)

      # For debugging if needed:
      # Rails.logger.debug "Gemini json_text: #{json_text.inspect}"

      parsed_json = JSON.parse(json_text)

      ideas =
        case parsed_json
        when Hash
          # Prefer the expected key, but allow a couple of fallbacks
          parsed_json["gift_ideas"] || parsed_json["ideas"] || parsed_json["data"]
        when Array
          # Model returned a top-level array of ideas
          parsed_json
        else
          nil
        end

      unless ideas.is_a?(Array)
        snippet = json_text.to_s[0, 300]
        raise Error,
              "Unexpected JSON structure from Gemini (expected an array of gift ideas). " \
                "Top-level class: #{parsed_json.class}, snippet: #{snippet.inspect}"
      end

      ideas
    rescue JSON::ParserError => e
      raise Error, "Failed to parse Gemini JSON: #{e.message}"
    end

    private

    # In JSON mode, the model usually returns the JSON as text in the first candidate.
    def extract_json_text(parsed_response)
      candidates = parsed_response["candidates"]
      raise Error, "Gemini response has no candidates" if candidates.blank?

      first = candidates.first
      content = first["content"] || {}
      parts = content["parts"] || []
      text_part = parts.find { |p| p["text"].present? }

      raise Error, "Gemini response has no text parts" if text_part.nil?

      text_part["text"]
    end
  end
end
