module HealthkitImporting
  class ImportRecord < ActiveRecord::Base
    self.table_name = 'healthkit_records'
  end
end
