#!/usr/bin/env ruby

require 'fileutils'

class HousekeepingAnalyzer
  def self.call(repo_path)
    new(repo_path).call
  end

  def initialize(repo_path)
    @repo_path = normalize_path(repo_path)
  end

  def call
    FileUtils.cd(repo_path)

    output = `git grep -lE "TODO|FIXME" | xargs -n1 git blame -f -n -w | grep -iE "TODO|FIXME" | sed "s/.\{9\}//" | sed "s/(.*)[[:space:]]*//"`

    issues = build_issues(output)

    issues.
      group_by(&:file).
      sort_by { |_, issues| issues.count }.
      reverse.
      each { |file, issues| print "#{file}: #{issues.count}\n" }
  end

  private
  attr_reader :repo_path

  def build_issues(output)
    output.split("\n").map do |str|
      components = str.split(' ')[1..-1]
      file = components.shift
      line = components.shift
      desc = components.join(' ')

      Issue.new(file, line, desc)
    end
  end

  def ignored_files
    @ignored_files ||= File.
                       read(File.open("#{repo_path}/.gitignore")).
                       split("\n")
  end

  def normalize_path(path)
    return path.chars[0..-2].join if path.chars.last == '/'

    path
  end
end

class Issue
  attr_reader :file, :ln, :description

  def initialize(file, ln, description)
    @file = file
    @ln = ln
    @description = description
  end
end

unless ARGV.any?
  "Call with `ruby housekeeping_analyzer.rb REPO_PATH`"
else
  HousekeepingAnalyzer.call(ARGV[0])
end
