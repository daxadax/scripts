#!/usr/bin/env ruby
# Upload a file to Backblaze B2, then notify Telegram via NotificationBot.
#
# Required ENV:
#   B2_* vars (see upload_media.rb)
#   NOTIFICATION_BOT_URL (e.g. https://your-app.herokuapp.com/notify)
#
# Usage:
#   export NOTIFICATION_BOT_URL='https://your-app.herokuapp.com/notify'
#   ruby upload_media_and_send_to_chat.rb ~/clip.mkv --bucket notifications --target-id YOUR_CHAT_ID --text "clip"

require 'json'
require 'net/http'
require 'optparse'
require 'uri'

require File.expand_path('backblaze/upload_media', __dir__)

VIDEO_EXTENSIONS = %w[.mkv .mp4 .webm .mov].freeze

options = {
  bucket: nil,
  key: nil,
  target_id: nil,
  text: nil,
  public_key: nil,
  private_key: nil,
  force_upload: false,
  notify_url: ENV['NOTIFICATION_BOT_URL']
}

parser = OptionParser.new do |opts|
  opts.banner = 'Usage: upload_media_and_send_to_chat.rb FILE --bucket BUCKET --target-id ID [options]'
  opts.on('--bucket BUCKET', 'B2 bucket name') { |value| options[:bucket] = value }
  opts.on('--key KEY', 'Object key in bucket') { |value| options[:key] = value }
  opts.on('--target-id ID', 'Telegram chat id') { |value| options[:target_id] = value }
  opts.on('--text TEXT', 'Optional caption/message') { |value| options[:text] = value }
  opts.on('--public-key KEY', 'B2 application key id (default: B2_PUBLIC_KEY)') { |value| options[:public_key] = value }
  opts.on('--private-key KEY', 'B2 application key (default: B2_PRIVATE_KEY)') { |value| options[:private_key] = value }
  opts.on('--force-upload', 'Upload even if object key already exists on B2') { options[:force_upload] = true }
  opts.on('--notify-url URL', 'NotificationBot endpoint (default: NOTIFICATION_BOT_URL env)') { |value| options[:notify_url] = value }
end
parser.parse!

file_path = ARGV.shift
abort(parser.help) if file_path.nil? || options[:bucket].nil? || options[:target_id].nil?
abort('Set NOTIFICATION_BOT_URL or pass --notify-url') if options[:notify_url].nil? || options[:notify_url].empty?

media_url = Backblaze::UploadMedia.call(
  file_path: file_path,
  bucket: options[:bucket],
  key: options[:key],
  public_key: options[:public_key],
  private_key: options[:private_key],
  skip_if_exists: !options[:force_upload]
)

ext = File.extname(file_path).downcase
payload = {
  'target_id' => options[:target_id],
  'text' => options[:text]
}.compact

if VIDEO_EXTENSIONS.include?(ext)
  payload['video_url'] = media_url
else
  payload['photo_url'] = media_url
end

uri = URI(options[:notify_url])
response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = payload.to_json
  http.request(request)
end

warn "B2 URL: #{media_url}"
puts response.body
exit(1) unless response.is_a?(Net::HTTPSuccess)
