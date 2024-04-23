require 'json'
require 'csv'
require 'fileutils'

class ListRepositories
  BASE_API = 'https://api.github.com/'.freeze
  ACCESS_TOKEN = ENV['GITHUB_API_KEY']

  def initialize(owner)
    @owner = owner
  end

  def list
    print "\n"

    write_repositories
  end

  private
  attr_reader :owner

  def write_repositories
    api_path = "#{BASE_API}orgs/#{owner}/repos?per_page=100"
    csv_path = "#{Dir.home}/#{owner}_repos.csv"

    # make sure it exists
    FileUtils.touch(csv_path)

    results = fetch_results(api_path).sort_by { |repo| repo['updated_at'] }.reverse

    # write csv
    CSV.open(csv_path, "w+") do |csv|
      csv << %w[required name url updated_at comments]
      results.map do |repo|
        csv << [nil, repo['name'], repo['url'], repo['pushed_at'], nil]
      end
    end

    # print path to console
    print "CSV file saved to #{csv_path}"
  end

  def fetch_results(api_path)
    JSON.parse(`curl -s -H "Authorization: token #{ACCESS_TOKEN}" #{api_path}`)
  end
end

# 0 = owner
ListRepositories.new(ARGV[0]).list
