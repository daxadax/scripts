#!/usr/bin/env ruby
# Upload a local file to Backblaze B2 and return its public download URL.
#
# Required ENV (unless --public-key/--private-key are passed):
#   B2_PUBLIC_KEY, B2_PRIVATE_KEY
#   B2_KNOWN_BUCKETS (comma-separated bucket names)
#   B2_<BUCKET>_BUCKET_ID (e.g. B2_NOTIFICATIONS_BUCKET_ID)
#
# Optional ENV:
#   B2_AUTH_URL (defaults to Backblaze authorize endpoint)
#
# Usage:
#   ruby upload_media.rb path/to/file.mkv --bucket notifications
#   ruby upload_media.rb path/to/file.mkv --bucket notifications --key clips/2026/clip.mkv
#   MKV inputs are remuxed to MP4 before upload for iPhone/Telegram compatibility.

require 'json'
require 'net/http'
require 'uri'
require 'digest'
require 'optparse'
require 'cgi'
require 'tempfile'

require_relative 'credentials'

module Backblaze
  class UploadMedia
    AuthenticationError = Class.new(StandardError)
    UploadError = Class.new(StandardError)

    DEFAULT_AUTH_URL = 'https://api.backblazeb2.com/b2api/v2/b2_authorize_account'

    CONTENT_TYPES = {
      '.mkv' => 'video/x-matroska',
      '.mp4' => 'video/mp4',
      '.webm' => 'video/webm',
      '.mov' => 'video/quicktime',
      '.png' => 'image/png',
      '.jpg' => 'image/jpeg',
      '.jpeg' => 'image/jpeg',
      '.gif' => 'image/gif'
    }.freeze

    def self.call(file_path:, bucket:, key: nil, public_key: nil, private_key: nil, skip_if_exists: true)
      new(file_path:, bucket:, key:, public_key:, private_key:, skip_if_exists:).call
    end

    def initialize(file_path:, bucket:, key: nil, public_key: nil, private_key: nil, skip_if_exists: true)
      @source_path = file_path
      @bucket = bucket
      @key = key
      @skip_if_exists = skip_if_exists
      @credentials = Credentials.fetch(public_key:, private_key:)
      @converted_tempfile = nil
    end

    def call
      raise AuthenticationError, "Unknown bucket: #{bucket}" unless known_bucket?
      raise ArgumentError, "File not found: #{source_path}" unless File.file?(source_path)

      auth = authorize
      url = public_url(auth)

      if skip_if_exists? && file_exists?(auth)
        warn "Already on B2, skipping upload: #{url}"
        return url
      end

      prepare_upload!
      upload_data = upload_url(auth)
      upload_file(upload_data)
      url
    ensure
      cleanup_converted_file
    end

    private

    attr_reader :source_path, :bucket, :key, :credentials, :skip_if_exists, :upload_path

    def skip_if_exists?
      skip_if_exists
    end

    def file_exists?(auth)
      uri = URI("#{auth['apiUrl']}/b2api/v2/b2_list_file_names")
      result = request_json(
        :post,
        uri,
        body: { bucketId: bucket_id, prefix: object_key, maxFileCount: 1 },
        token: auth['authorizationToken']
      )

      result.fetch('files', []).any? { |file| file['fileName'] == object_key }
    end

    def known_buckets
      ENV.fetch('B2_KNOWN_BUCKETS').split(',').map(&:strip)
    end

    def known_bucket?
      known_buckets.include?(bucket)
    end

    def bucket_id
      env_key = bucket_id_env_key
      value = ENV[env_key]
      raise AuthenticationError, "Missing #{env_key} for bucket #{bucket}" if value.nil? || value.empty?

      value
    end

    def bucket_id_env_key
      "B2_#{bucket.upcase.tr('-', '_')}_BUCKET_ID"
    end

    def prepare_upload!
      if mkv_input?
        warn "Remuxing MKV to MP4: #{source_path}"
        @converted_tempfile = remux_mkv_to_mp4
        @upload_path = @converted_tempfile.path
      else
        @upload_path = source_path
      end
    end

    def mkv_input?
      File.extname(source_path).casecmp('.mkv').zero?
    end

    def remux_mkv_to_mp4
      out = Tempfile.new(['upload', '.mp4'])
      out.close
      ok = system('ffmpeg', '-nostdin', '-y', '-i', source_path, '-c', 'copy', out.path)
      raise UploadError, "ffmpeg remux failed for #{source_path}" unless ok && $?.success?

      out
    end

    def cleanup_converted_file
      return unless @converted_tempfile

      @converted_tempfile.close
      @converted_tempfile.unlink
      @converted_tempfile = nil
    end

    def object_key
      @object_key ||= begin
        name = key || File.basename(source_path)
        mkv_input? ? name.sub(/\.mkv\z/i, '.mp4') : name
      end
    end

    def content_type
      ext = File.extname(upload_path).downcase
      CONTENT_TYPES.fetch(ext) { 'application/octet-stream' }
    end

    def auth_url
      ENV.fetch('B2_AUTH_URL', DEFAULT_AUTH_URL)
    end

    def authorize
      request_json(:get, URI(auth_url), basic_auth: true)
    end

    def upload_url(auth)
      uri = URI("#{auth['apiUrl']}/b2api/v2/b2_get_upload_url")
      request_json(:post, uri, body: { bucketId: bucket_id }, token: auth['authorizationToken'])
    end

    def upload_file(upload_data)
      uri = URI(upload_data['uploadUrl'])
      file_body = File.binread(upload_path)

      request_raw(
        :post,
        uri,
        body: file_body,
        headers: {
          'Authorization' => upload_data['authorizationToken'],
          'X-Bz-File-Name' => encoded_object_key,
          'Content-Type' => content_type,
          'Content-Length' => file_body.bytesize.to_s,
          'X-Bz-Content-Sha1' => Digest::SHA1.hexdigest(file_body)
        },
        retries: 3
      )
    end

    def encoded_object_key
      # B2 requires URL-encoded file names in X-Bz-File-Name
      CGI.escape(object_key).gsub('+', '%20')
    end

    def public_url(auth)
      encoded_key = object_key.split('/').map { |part| CGI.escape(part) }.join('/')
      "#{auth['downloadUrl']}/file/#{bucket}/#{encoded_key}"
    end

    def request_json(method, uri, body: nil, token: nil, basic_auth: false)
      headers = { 'Content-Type' => 'application/json' }
      headers['Authorization'] = token if token
      payload = body&.to_json

      response = request_raw(method, uri, body: payload, headers: headers, basic_auth: basic_auth)
      JSON.parse(response.body)
    end

    def request_raw(method, uri, body: nil, headers: {}, basic_auth: false, retries: 0)
      attempt = 0
      max_attempts = retries + 1

      loop do
        attempt += 1
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          request = Net::HTTP.const_get(method.capitalize).new(uri)
          headers.each { |name, value| request[name] = value }
          if basic_auth
            request.basic_auth(credentials[:public_key], credentials[:private_key])
          end
          request.body = body if body
          http.request(request)
        end

        return response if response.is_a?(Net::HTTPSuccess)

        if attempt < max_attempts && %w[500 503].include?(response.code)
          sleep 0.5
          next
        end

        raise_b2_error(response, uri)
      end
    rescue UploadError, AuthenticationError
      raise
    rescue StandardError => e
      raise UploadError, "B2 request error for #{uri}: #{e.message}"
    end

    def raise_b2_error(response, uri)
      detail = {
        code: response.code,
        body: response.body,
        bucket: bucket,
        object_key: object_key,
        bucket_id_env: bucket_id_env_key
      }

      hint = if response.code == '401' || response.body.include?('unauthorized')
               'Check B2 application key has read/write access to this bucket.'
             elsif response.code == '500'
               'Often wrong bucket id env var, key permissions, or a transient B2 error. Retry with --force-upload.'
             else
               'Check bucket name, object key, and B2 credentials.'
             end

      raise UploadError, "B2 request failed (#{detail[:code]}) uploading #{object_key} to #{bucket}: #{detail[:body]}. #{hint}"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  options = { bucket: nil, key: nil, public_key: nil, private_key: nil, force_upload: false }
  parser = OptionParser.new do |opts|
    opts.banner = 'Usage: upload_media.rb FILE --bucket BUCKET [--key OBJECT_KEY]'
    opts.on('--bucket BUCKET', 'B2 bucket name') { |value| options[:bucket] = value }
    opts.on('--key KEY', 'Object key in bucket (default: basename of file)') { |value| options[:key] = value }
    opts.on('--public-key KEY', 'B2 application key id (default: B2_PUBLIC_KEY)') { |value| options[:public_key] = value }
    opts.on('--private-key KEY', 'B2 application key (default: B2_PRIVATE_KEY)') { |value| options[:private_key] = value }
    opts.on('--force-upload', 'Upload even if object key already exists on B2') { options[:force_upload] = true }
  end
  parser.parse!

  file_path = ARGV.shift
  abort(parser.help) if file_path.nil? || options[:bucket].nil?

  url = Backblaze::UploadMedia.call(
    file_path: file_path,
    bucket: options[:bucket],
    key: options[:key],
    public_key: options[:public_key],
    private_key: options[:private_key],
    skip_if_exists: !options[:force_upload]
  )
  puts url
end
