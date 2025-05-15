require 'google/apis/sheets_v4'
require 'googleauth'

class UpdateGoogleDriveFile
  RANGE = 'Sheet1!A1' # overwrite the whole sheet

  def self.call(credentials_path:, file_id:, file_path:)
    new(credentials_path, file_id, file_path).call
  end

  def initialize(credentials_path, file_id, file_path)
    @file_id = file_id
    @file_path = file_path

    @client = Google::Apis::SheetsV4::SheetsService.new
    client.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: 'https://www.googleapis.com/auth/spreadsheets'
    )
  end

  def call
    # truncate sheet
    client.clear_values(file_id, 'Sheet1')

    # Data to write
    values = CSV.read(file_path)
    value_range = Google::Apis::SheetsV4::ValueRange.new(values: values)

    # Write the data
    client.update_spreadsheet_value(
      file_id,
      RANGE,
      value_range,
      value_input_option: 'RAW'
    )
  end

  private
  attr_reader :client, :file_id, :file_path
end

