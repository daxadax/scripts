require 'csv'
require './retrieve_squarespace_orders'
require '../update_google_drive_file'

class PCBMain
  GDRIVE_CREDENTIALS_PATH = './gdrive_credentials.json'
  PCB_ORDERS_SHEET_ID = ENV['PCB_ORDERS_SHEET_ID']
  ORDERS_CSV_PATH     = "./orders.csv"

  def self.call
    orders = RetrieveSquarespaceOrders.call

    CSV.open(ORDERS_CSV_PATH, 'w+') do |csv|
      csv << orders.first.keys

      orders.each do |order|
        csv << order.values
      end
    end

    UpdateGoogleDriveFile.call(
      credentials_path: GDRIVE_CREDENTIALS_PATH,
      file_id: PCB_ORDERS_SHEET_ID,
      file_path: ORDERS_CSV_PATH
    )
  end
end

PCBMain.call
