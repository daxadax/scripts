# To be used with backblaze service
#
# the follow ENV variables are required to be set:
# B2_KNOWN_BUCKETS - array of accepted bucket names
# B2_AUTH_URL
# B2_PUBLIC_KEY
# B2_PRIVATE_KEY

module Backblaze
  class ReadFile
    AuthenticationError = Class.new(::StandardError)

    B2_KNOWN_BUCKETS = ENV['B2_KNOWN_BUCKETS']
    B2_AUTH_URL = ENV['B2_AUTH_URL']
    B2_PUBLIC_KEY = ENV['B2_PUBLIC_KEY']
    B2_PRIVATE_KEY = ENV['B2_PRIVATE_KEY']

    def self.call(bucket:, filename:)
      new(bucket, filename).call
    end

    def initialize(bucket, filename)
      @bucket = bucket
      @filename = filename
    end

    def call
      raise AuthenticationError, "Unknown bucket: #{bucket}" unless valid_bucket?

      # create connection for reading
      conn = Faraday.new(B2_AUTH_URL) do |conn|
        conn.request :authorization, :basic, B2_PUBLIC_KEY, B2_PRIVATE_KEY
      end

      response = conn.get
      return response unless response.success?

      auth = JSON.parse(response.body)
      download_url = "#{auth['downloadUrl']}/file/#{bucket}/#{filename}"

      Faraday.get(download_url) do |request|
        request.headers['Authorization'] = auth['authorizationToken']
      end
    end

    private
    attr_reader :bucket, :filename

    def valid_bucket?
      B2_KNOWN_BUCKETS.include?(bucket)
    end
  end
end
