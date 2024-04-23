class CollectFilesForRubocop
  def self.call
    new.call
  end

  def initialize
    @active_changes = `git status --short`
    @changed_files = `git diff --summary master..HEAD | uniq`
  end

  def call
    target_files = parse_changed_files + parse_active_changes

    target_files.reject! { |f| !f.match?('.rb') }
    target_files.reject! { |f| f.match?('^db\/') }
    target_files.join(' ')
  end

  private
  attr_reader :active_changes, :changed_files

  # format: 'delete xxx xxx filename'
  def parse_changed_files
    changed_files.split("\n").map do |diff_row|
      columns = diff_row.strip.split
      action = columns.first

      next if action == 'delete'

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
