module Report
  module Patients
    class Duplicates

      attr_reader :business, :result

      def initialize(business)
        @business = business
        calculate
      end

      def self.make(business)
        new(business)
      end

      private

      def calculate
        @result = {}
        query = %{
          SELECT LOWER(full_name) AS full_name, ARRAY_AGG(id) AS ids
          FROM patients
          WHERE business_id = :business_id AND deleted_at IS NULL AND archived_at IS NULL
          GROUP BY LOWER(full_name)
          HAVING COUNT(*) > 1
        }
        rows = ActiveRecord::Base.connection.exec_query(
          ActiveRecord::Base.send(:sanitize_sql_array, [
            query,
            {
              business_id: business.id
            }
          ])
        ).to_a

        duplicates = []
        patient_ids = []
        rows.each do |row|
          ids = row['ids'].gsub(%r({|}), '').split(',').map(&:to_i).sort
          duplicates << {
            ids: ids,
            full_name: row['full_name'],
            patients: []
          }

          patient_ids += ids
        end

        patients = business.patients.
          where(id: patient_ids).
          joins('LEFT JOIN appointments ON appointments.patient_id = patients.id AND appointments.deleted_at IS NULL').
          joins('LEFT JOIN treatment_notes ON treatment_notes.patient_id = patients.id').
          select('patients.*', 'COUNT(DISTINCT appointments.id) AS appointments_count', 'COUNT(DISTINCT treatment_notes.id) AS treatment_notes_count').
          group('patients.id').
          order(id: :asc)

        duplicates.each do |dup|
          dup[:patients] = patients.select do |p|
            dup[:ids].include? p.id
          end
        end

        @result[:duplicates] = duplicates
      end
    end
  end
end
