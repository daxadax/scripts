# To be used with backblaze service
#
# the follow ENV variables are required to be set:
# B2_KNOWN_BUCKETS - array of accepted bucket names
# B2_AUTH_URL
# B2_PUBLIC_KEY
# B2_PRIVATE_KEY

require_relative 'credentials'

module Backblaze
  class ReadFile
    AuthenticationError = Class.new(::StandardError)

    def self.call(bucket:, filename:, target_path: nil, public_key: nil, private_key: nil)
      new(bucket, filename, target_path, public_key:, private_key:).call
    end

    def initialize(bucket, filename, target_path, public_key: nil, private_key: nil)
      @bucket = bucket
      @filename = filename
      @target_path = target_path
      @credentials = Credentials.fetch(public_key:, private_key:)
    end

    def call
      raise AuthenticationError, "Unknown bucket: #{bucket}" unless valid_bucket?

      conn = Faraday.new(auth_url) do |conn|
        conn.request :authorization, :basic, credentials[:public_key], credentials[:private_key]
      end

      response = conn.get
      return response unless response.success?

      auth = JSON.parse(response.body)
      download_url = "#{auth['downloadUrl']}/file/#{bucket}/#{filename}"

      download = Faraday.get(download_url) do |request|
        request.headers['Authorization'] = auth['authorizationToken']
      end

      file = Tempfile.new("tempfile-#{Time.now.utc.to_i}")
      file.write(download.body)
      file.rewind

      if target_path
        system("tar -xf #{file.path} -O > #{target_path}")
      else
        system("tar -xf #{file.path} -O")
      end
    end

    private

    attr_reader :bucket, :filename, :target_path, :credentials

    def auth_url
      ENV.fetch('B2_AUTH_URL')
    end

    def known_buckets
      ENV.fetch('B2_KNOWN_BUCKETS').split(',').map(&:strip)
    end

    def valid_bucket?
      known_buckets.include?(bucket)
    end
  end
end
