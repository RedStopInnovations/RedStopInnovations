module Claiming
  module BulkBill
    class PaymentAvailability
      attr_reader :business, :invoice, :errors

      def initialize(invoice)
        @invoice = invoice
        @business = invoice.business
        @errors = {}
        check_integration_active_for_business(business)
        validate_patient(invoice.patient)
        validate_invoice(invoice)
        if invoice.appointment
          validate_practitioner(invoice.appointment.practitioner)
        end
      end

      private

      def check_integration_active_for_business(business)
        if business.claiming_auth_group.nil?
          errors[:business] = 'The Medicare & DVA integration is not enabled yet.'
        end
      end

      def validate_patient(patient)
        error = nil

        if patient.medicare_details.blank?
          error = 'The client\'s Medicare details is missing.'
        end

        if error.blank? && patient.medicare_card_number.blank?
          error = 'The client\'s Medicare card number is missing.'
        end

        if error.blank? && patient.medicare_card_irn.blank?
          error = 'The client\'s Medicare card IRN is missing.'
        end

        if error.blank? && patient.dob.blank?
          error = 'The client\'s dob is missing.'
        end

        if error.blank?
          verify_response = claiming_api_client.verify_patient(
            Claiming::Dva::VerifyPatientData.new(patient).data
          )
          json_res = JSON.parse(verify_response.body)
          unless verify_response.success? &&
                 json_res.dig('status', 'dva', 'code') == 0
            error = json_res.dig('status', 'dva', 'message')
            error ||= json_res['message']
            if error.blank?
              error = 'Unknown.'
            end
            error = "Failed to verify patient info with Medicare. Error: #{error}"
          end
        end

        if error
          errors[:patient] = error
        end
      end

      def validate_invoice(invoice)
        error = nil

        if invoice.items.length == 0
          error = 'The invoice has no any items.'
        end

        if error.blank? && invoice.appointment.nil?
          error = 'The invoice is not issued for an appointment.'
        end

        if error.blank?
          has_non_claimable_item = invoice.items.billable_item.any? do |invoice_item|
            !invoice_item.invoiceable.is_bulkbill_item?
          end

          if has_non_claimable_item
            error = 'The invoice contains non-claimable items for BulkBill.'
          end
        end

        if error
          errors[:invoice] = error
        end
      end

      def validate_practitioner(practitioner)
        error = nil

        if practitioner.medicare.blank?
          error = 'The practitioner\'s provider number is not set.'
        end

        if error.blank? && practitioner.medicare.present? && business.claiming_auth_group.present?
          if !business.claiming_auth_group.providers.where(provider_number: practitioner.medicare).exists?
            error = 'The practitioner\'s provider number is not registered for claiming.'
          end
        end

        if error
          errors[:practitioner] = error
        end
      end

      def verify_patient_dva_info(patient)
        claiming_api_client.verify_patient(
          Claiming::BulkBill::VerifyPatientData.new(patient).data
        )
      end

      def claiming_api_client
        @claiming_api_client ||= ClaimingApi::Client.new
      end
    end
  end
end
