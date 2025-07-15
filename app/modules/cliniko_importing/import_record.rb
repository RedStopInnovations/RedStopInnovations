module ClinikoImporting
  class ImportRecord < ActiveRecord::Base
    self.table_name = 'cliniko_records'
  end
end
