# To be used with backblaze service
#
# the follow ENV variables are required to be set:
# B2_KNOWN_BUCKETS - array of accepted bucket names
# B2_AUTH_URL
# B2_PUBLIC_KEY
# B2_PRIVATE_KEY

require_relative 'credentials'

module Backblaze
  class WriteFile
    AuthenticationError = Class.new(::StandardError)

    def self.call(filename:, bucket:, year:, author:, compress: true, extension: 'csv', public_key: nil, private_key: nil)
      new(filename, bucket, year, author, compress, extension, public_key:, private_key:).call
    end

    def initialize(filename, bucket, year, author, compress, extension, public_key: nil, private_key: nil)
      @filename = filename
      @bucket = bucket
      @year = year
      @author = author
      @compress = compress
      @extension = extension
      @credentials = Credentials.fetch(public_key:, private_key:)
    end

    def call
      raise AuthenticationError, "Unknown bucket: #{bucket}" unless valid_bucket?

      bucket_id = ENV[bucket_id_env_key]
      dumpfile = "#{filename}.#{extension}"
      tarfile = compress? ? "#{filename.split('/').last}.tar.gz" : dumpfile

      begin
        system("tar -czvf #{tarfile} #{dumpfile}") if compress?

        conn = Faraday.new(auth_url) do |conn|
          conn.request :authorization, :basic, credentials[:public_key], credentials[:private_key]
        end

        response = conn.get

        raise AuthenticationError unless response.success?
        auth = JSON.parse(response.body)
        b2_get_upload_url = "#{auth['apiUrl']}/b2api/v2/b2_get_upload_url"

        response = Faraday.post(b2_get_upload_url) do |request|
          request.headers['Authorization'] = auth['authorizationToken']
          request.body = { bucketId: bucket_id }.to_json
        end

        raise AuthenticationError unless response.success?
        upload_data = JSON.parse(response.body)
        sha1 = Digest::SHA1.new

        File.open(tarfile) do |f|
          f.lazy.each_slice(1000) do |lines|
            lines.each { |line| sha1.update(line) }
          end
        end

        upload_filename = compress? ? tarfile : dumpfile.split('/').last
        file_to_upload = "#{year}/#{upload_filename}"

        conn = Faraday.new do |f|
          f.request :retry, {
            max: 5,
            interval: 0.3,
            interval_randomness: 0.5,
            retry_statuses: [503]
          }
        end

        response = conn.post(upload_data['uploadUrl']) do |request|
          request.headers['Authorization'] = upload_data['authorizationToken']
          request.headers['X-Bz-File-Name'] = file_to_upload
          request.headers['Content-Type'] = content_type
          request.headers['X-Bz-Content-Sha1'] = sha1.hexdigest
          request.headers['X-Bz-Info-Author'] = author
          request.body = File.read(tarfile)
        end

        if response.success?
          { success: true, msg: "File #{dumpfile.split('/').last} uploaded successfully" }
        else
          { success: false, msg: "Failed to upload #{tarfile}: #{response.body}" }
        end
      ensure
        FileUtils.rm(tarfile) if compress?
      end
    end

    private

    attr_reader :filename, :bucket, :year, :author, :extension, :credentials

    def auth_url
      ENV.fetch('B2_AUTH_URL')
    end

    def known_buckets
      ENV.fetch('B2_KNOWN_BUCKETS').split(',').map(&:strip)
    end

    def valid_bucket?
      known_buckets.include?(bucket)
    end

    def bucket_id_env_key
      "B2_#{bucket.upcase.split('-').join('_')}_BUCKET_ID"
    end

    def compress?
      @compress
    end

    def content_type
      return 'application/gzip' if compress?
      return 'application/json' if extension == 'json'

      'application/csv'
    end
  end
end
