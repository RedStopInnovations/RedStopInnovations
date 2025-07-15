FactoryBot.define do
  factory :patient_case do
    notes { FFaker::Lorem.paragraph }
    status { ['Open', 'Discharged'].sample }
    # practitioner_id
    # case_type_id
    # patient_id
    # invoice_total
    # invoice_number

  end
end
