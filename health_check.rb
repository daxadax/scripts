#!/usr/bin/env ruby

class HealthCheck
  def initialize(url)
    @url = url
    @result = `curl -Ls -o /dev/null -w %{http_code} #{url}`
  end

  def status
    result.strip.to_i
  end

  def healthy?
    return true if status == 200

    false
  end

  private
  attr_reader :url, :result
end
