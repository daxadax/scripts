require 'pry'

class CollectFilesForRubocop
  def self.call
    new.call
  end

  def initialize
    @active_changes = `git status --short`

    main_branch = `git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'`
    @changed_files = `git diff --name-status #{main_branch}`
  end

  def call
    target_files = parse_changed_files + parse_active_changes

    target_files.reject! { |f| !f.match?('.rb') }
    target_files.reject! { |f| f.match?('^db\/') }
    target_files.join(' ')
  end

  private
  attr_reader :active_changes, :changed_files

  # format: 'M filename'
  # format: 'D filename'
  def parse_changed_files
    changed_files.split("\n").map do |diff_row|
      columns = diff_row.strip.split

      # don't check deleted files
      next if columns.first == 'D'

      columns.last # filename
    end.compact
  end

  # format: 'D filename'
  def parse_active_changes
    active_changes.split("\n").map do |diff_row|
      columns = diff_row.strip.split

      next if columns.first == 'D'

      columns.last # filename
    end.compact
  end
end

print CollectFilesForRubocop.call
