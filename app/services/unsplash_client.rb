# app/services/unsplash_client.rb
require "net/http"
require "uri"
require "json"
require "cgi"
require "openssl"

class UnsplashClient
  class Error < StandardError; end

  def initialize(access_key: nil, api_base: nil)
    creds = Rails.application.credentials

    @access_key =
      access_key ||
      ENV["UNSPLASH_ACCESS_KEY"] ||
      creds.dig(:unsplash, :access_key)

    @api_base =
      api_base ||
      ENV["UNSPLASH_API_BASE"] ||
      creds.dig(:unsplash, :api_base) ||
      "https://api.unsplash.com"

    raise Error, "Unsplash access key missing" if @access_key.blank?
  end

  # Returns a single image URL string or nil
  def search_image(query)
    return nil if query.blank?

    uri = URI.parse("#{@api_base}/search/photos?query=#{CGI.escape(query)}&per_page=1")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    # 🔐 Dev-only workaround for SSL CRL issues on some local environments
    if Rails.env.development?
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    request = Net::HTTP::Get.new(uri.request_uri)
    request["Authorization"] = "Client-ID #{@access_key}"

    response = http.request(request)

    return nil unless response.is_a?(Net::HTTPSuccess)

    parsed = JSON.parse(response.body)
    result = parsed["results"]&.first
    return nil unless result

    (result["urls"] || {})["small"] || result["urls"]["regular"]
  rescue JSON::ParserError
    nil
  end

end
