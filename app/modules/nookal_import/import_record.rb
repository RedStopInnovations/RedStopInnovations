module NookalImport
  class ImportRecord < ActiveRecord::Base
    self.table_name = 'nookal_records'
  end
end
