module Api
  module V1
    module JsonApiHelper
      def jsonapi_class
        {
          Appointment: AppointmentSerializer,
          AppointmentArrival: AppointmentArrivalSerializer,
          Availability: AvailabilitySerializer,
          Contact: ContactSerializer,
          Invoice: InvoiceSerializer,
          AppointmentType: AppointmentTypeSerializer,
          Patient: PatientSerializer,
          InvoiceItem: InvoiceItemSerializer,
          BillableItem: BillableItemSerializer,
          Practitioner: PractitionerSerializer,
          Product: ProductSerializer,
          Tax: TaxSerializer,
          Payment: PaymentSerializer,
          Business: BusinessSerializer,
          Task: TaskSerializer,
          User: UserSerializer,
          TreatmentNote: TreatmentSerializer,
          PatientAttachment: PatientAttachmentSerializer,
          PatientContact: PatientContactSerializer,
          Referral: ReferralSerializer,
          ReferralAttachment: ReferralAttachmentSerializer,
        }
      end

      def jsonapi_object
        { version: '1.0' }
      end
    end
  end
end
