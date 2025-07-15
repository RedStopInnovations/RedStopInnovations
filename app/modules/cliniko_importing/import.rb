module ClinikoImporting
  class Import < ActiveRecord::Base
    DATA_TYPES = [
      DATA_TYPE_PATIENT        = 'Patient',
      DATA_TYPE_TREATMENT_NOTE = 'TreatmentNote'
    ]

    STATUSES = [
      STATUS_PENDING     = 'Pending',
      STATUS_IN_PROGRESS = 'In Progress',
      STATUS_ERROR       = 'Completed',
      STATUS_COMPLETED   = 'Error'
    ]

    self.table_name = 'cliniko_imports'

    serialize :result, type: Hash

    has_many :records,
             class_name: 'ClinikoImporting::ImportRecord',
             foreign_key: :import_id

    validates :data_type,
              presence: true,
              inclusion: { in: DATA_TYPES }

    validates :business_id, :api_key, :status, presence: true
  end
end
