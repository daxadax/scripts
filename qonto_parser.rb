#!/usr/bin/env ruby

require 'csv'
require 'date'
require 'fileutils'
require 'zip'
require './zip_file_generator.rb'

class QontoParser
  def self.call(zip_archive_path)
    new(zip_archive_path).call
  end

  def initialize(zip_archive_path)
    @zip_archive_path = zip_archive_path
    @tmp_dir = '/tmp/qonto-parser'
    @income_dir = '/tmp/qonto-parser/income'
    @expense_dir = '/tmp/qonto-parser/expense'
    @start_time = Time.now
    @archiver = ZipFileGenerator
  end

  def call
    puts 'Creating temporary directories..'
    FileUtils.mkdir_p(tmp_dir)
    FileUtils.mkdir_p(@income_dir)
    FileUtils.mkdir_p(@expense_dir)

    puts 'Extracting files from archive..'
    extract_archive

    manifest_csv_path = Dir["#{tmp_dir}/*.csv"].first

    puts 'Creating income/expense ledgers..'
    income = CSV.read(manifest_csv_path).first
    expense = CSV.read(manifest_csv_path).first

    puts 'Separating files by category..'
    CSV.read(manifest_csv_path, headers: true).each do |row|
      attachments = row['Attachment'].split('|').map(&:strip)

      if row['Debit'].nil?
        income << row
        attachments.each { |a| move_to_dir(@income_dir, a) }
      end

      if row['Credit'].nil?
        expense << row
        attachments.each { |a| move_to_dir(@expense_dir, a) }
      end
    end

    puts 'Writing income/expense ledgers..'
    File.open("#{@income_dir}/income.csv", 'w+') { |f| f.write(income) }
    File.open("#{@expense_dir}/expense.csv", 'w+') { |f| f.write(expense) }

    puts 'Removing outdated manifest..'
    FileUtils.rm(manifest_csv_path)

    puts 'Determining name schema..'
    # NOTE don't take the first (few) entries, sometimes not correctly formatted
    date = Dir["#{@expense_dir}/*"][3].delete(@expense_dir).split.first.sub('-','')
    name = Date.parse(date).strftime('%Y-%B')

    puts 'Zipping together created files..'
    @archiver.new(tmp_dir, "/tmp/#{name}_qonto_export.zip").write

    puts 'Cleaning up..'
    FileUtils.rm_rf(Dir.glob("#{tmp_dir}/*"))

    puts "Done in #{Time.now - @start_time} seconds!"
  end

  private
  attr_reader :tmp_dir

  # NOTE: annoyingly, qonoto sometimes refers to the same file in two different
  # places, ie they say that invoice_a is related to both transaction_a and
  # transaction_b. this only seems to happen with qonto internal transaction
  # invoices - one solution is to copy these files rather than moving them,
  # cause when they're moved, they no longer exist in the original directory and
  # cause an error on the second operation. however then there are unnecessary
  # duplicates so the better solution, i think, is to not throw an error if the
  # file is missing but is already existing in the target directory
  def move_to_dir(dir, path)
    begin
      FileUtils.mv("#{tmp_dir}/#{path}", "#{dir}/")
    rescue Errno::ENOENT => e
      puts "File '#{path}' could not be found - if it's a Qonto file, it might be duplicated. If it's *not* a Qonto file, there is likely an error somewhere"
    end
  end

  def extract_archive
    Zip::File.open(@zip_archive_path) do |zip_file|
      # Handle entries one by one
      zip_file.each do |entry|
        # raise 'File too large when extracted' if entry.size > MAX_SIZE

        # Extract to file or directory based on name in the archive
        entry.extract("#{tmp_dir}/#{entry.name}")
      end
    end
  end
end

zip_archive_path = ARGV[0]

if zip_archive_path.nil? || zip_archive_path.empty?
  print "Please call 'ruby qonto_parser.rb ZIP_ARCHIVE_PATH'\n"
else
  QontoParser.call(zip_archive_path)
end
