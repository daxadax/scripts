require 'json'

class ListOpenPrs
  # NOTE: fill in repos here
  REPOS = %w[ ]
  BASE_API = 'https://api.github.com/'.freeze
  ACCESS_TOKEN = ENV['GITHUB_API_KEY']

  def initialize(owner)
    @owner = owner
  end

  def list
    print "\n"

    open_pull_requests.each do |repo, prs|
      print repo + "\n"

      if prs.count.zero?
        print "  no open pull requests\n"
      else
        prs.each do |pr|
          print bullet_point(pr) + title_for(pr['title']) + "\n"
        end
      end

      print "\n"
    end

    print "\n"
  end

  private
  attr_reader :owner

  def total_open_prs
    open_pull_requests.values.map(&:count).sum
  end

  def bullet_point(pr)
    return ' # ' if pr['draft']
    return ' ✓ ' if approvals_for(pr['url']) == 2

    ' • '
  end

  def approvals_for(pull_request)
    fetch_results("#{pull_request}/reviews").
      sum { |pr| pr['state'] == 'APPROVED' ? 1 : 0 }
  end

  def title_for(str)
    str.split('|').last.strip
  end

  def open_pull_requests
    return @open_pull_requests if defined?(@open_pull_requests)

    @open_pull_requests = Hash.new([])

    REPOS.each do |repo|
      api_path = "#{BASE_API}repos/#{owner}/#{repo}/pulls"
      @open_pull_requests[repo] = fetch_results(api_path)
    end

    @open_pull_requests
  end

  def fetch_results(api_path)
    JSON.parse(`curl -s -H "Authorization: token #{ACCESS_TOKEN}" #{api_path}`)
  end
end

# 0 = repo owner
status = ListOpenPrs.new(ARGV[0]).list
