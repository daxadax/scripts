# To be used with backblaze service
#
# the follow ENV variables are required to be set:
# B2_KNOWN_BUCKETS - array of accepted bucket names
# B2_AUTH_URL
# B2_PUBLIC_KEY
# B2_PRIVATE_KEY

# NOTE: currently only used for writing csv files so that assumption is made
# throughout the code. would need to be rewritten if that changes, or duplicated
# and rewritten for specific filetypes
module Backblaze
  class WriteFile
    AuthenticationError = Class.new(::StandardError)

    B2_KNOWN_BUCKETS = ENV['B2_KNOWN_BUCKETS']
    B2_AUTH_URL = ENV['B2_AUTH_URL']
    B2_PUBLIC_KEY = ENV['B2_PUBLIC_KEY']
    B2_PRIVATE_KEY = ENV['B2_PRIVATE_KEY']

    def self.call(filename:, bucket:, year:, author:, compress: true)
      new(filename, bucket, year, author, compress).call
    end

    def initialize(filename, bucket, year, author, compress)
      @filename = filename
      @bucket = bucket
      @year = year
      @author = author
      @compress = compress
    end

    def call
      raise AuthenticationError, "Unknown bucket: #{bucket}" unless valid_bucket?

      bucket_id = ENV["B2_#{bucket.upcase.split('-').join('_')}_BUCKET_ID"]
      csv_dumpfile = "#{filename}.csv"

      # use tarfile name if set to compress otherwise use existing csv filename
      tarfile = compress? ? "#{filename.split('/').last}.tar.gz" : csv_dumpfile

      begin
        # compress csv file
        # test.csv    => 387  MB
        # test.tar.gz => 90   MB
        system("tar -czvf #{tarfile} #{csv_dumpfile}") if compress?

        # move tar file to b2
        conn = Faraday.new(B2_AUTH_URL) do |conn|
          conn.request :authorization, :basic, B2_PUBLIC_KEY, B2_PRIVATE_KEY
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

        # include year as directory for sorting purposes
        upload_filename = compress? ? tarfile : csv_dumpfile.split('/').last
        file_to_upload = "#{year}/#{upload_filename}"

        response = Faraday.post(upload_data['uploadUrl']) do |request|
          request.headers['Authorization'] = upload_data['authorizationToken']
          request.headers['X-Bz-File-Name'] = file_to_upload
          request.headers['Content-Type'] = content_type
          request.headers['X-Bz-Content-Sha1'] = sha1.hexdigest
          request.headers['X-Bz-Info-Author'] = author
          request.body = File.read(tarfile)
        end

        if response.success?
          # clean up initial files / DB if desired

          { success: true, msg: "File #{filename}.csv uploaded successfully" }
        else
          { success: false, msg: "Failed to upload #{tarfile}: #{response.body}" }
        end
      ensure
        # remove generated tarfile
        FileUtils.rm(tarfile) if compress?
      end
    end

    private
    attr_reader :filename, :bucket, :year, :author

    def valid_bucket?
      B2_KNOWN_BUCKETS.include?(bucket)
    end

    def compress?
      @compress
    end

    def content_type
      return 'application/gzip' if compress?

      'application/csv'
    end
  end
end
