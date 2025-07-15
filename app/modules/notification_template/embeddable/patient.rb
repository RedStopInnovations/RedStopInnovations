module NotificationTemplate
  module Embeddable
    class Patient < Base
      VARIABLES = [
        'Patient.FullName',
        'Patient.FirstName',
        'Patient.LastName',
        'Patient.DateOfBirth',
        'Patient.Email',
        'Patient.Mobile',
        'Patient.Phone',
        'Patient.Gender',
        'Patient.FullAddress',
        'Patient.ShortAddress',
        'Patient.Address1',
        'Patient.Address2',
        'Patient.City',
        'Patient.State',
        'Patient.PostCode',
        'Patient.Country',
      ]

      # @param patient ::Patient
      def initialize(patient)
        @patient = patient
        super map_attributes
      end

      private

      def map_attributes
        map = {}

        map['Patient.FullName'] = @patient.full_name
        map['Patient.FirstName'] = @patient.first_name
        map['Patient.LastName'] = @patient.last_name
        map['Patient.DateOfBirth'] = @patient.dob.try(:strftime, I18n.t('date.dob'))
        map['Patient.Email'] = @patient.email
        map['Patient.Mobile'] = @patient.mobile
        map['Patient.Phone'] = @patient.phone
        map['Patient.Gender'] = @patient.gender
        map['Patient.FullAddress'] = @patient.full_address
        map['Patient.ShortAddress'] = @patient.short_address
        map['Patient.Address1'] = @patient.address1
        map['Patient.Address2'] = @patient.address2
        map['Patient.City'] = @patient.city
        map['Patient.State'] = @patient.state
        map['Patient.PostCode'] = @patient.postcode
        map['Patient.Country'] = @patient.country

        map
      end
    end
  end
end
