require 'json'

class GitStats
  def initialize(options)
    @options = options
    @raw_data = fetch_data
  end

  def stats
    @raw_data
  end

  private
  attr_reader :options

  def fetch_data
    command_string =  'git log --merges --pretty=format:"%b"'
    command_string += "--since='#{options[:start_date]}' " if options[:start_date]
    command_string += "--until='#{options[:end_date]}' " if options[:end_date]
    command_string += "--author='#{options[:author]}' " if options[:author]

    system(command_string)
  end
end


service = GitStats.new(
  start_date: ARGV[0],
  end_date: ARGV[1],
  author: ARGV[2] || 'dax'
)

p service.stats
