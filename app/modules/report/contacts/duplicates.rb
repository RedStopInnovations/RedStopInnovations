module Report
  module Contacts
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
          SELECT LOWER(business_name) AS business_name, ARRAY_AGG(id) AS ids
          FROM contacts
          WHERE business_id = :business_id AND deleted_at IS NULL
          GROUP BY LOWER(business_name)
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
        contact_ids = []
        rows.each do |row|
          ids = row['ids'].gsub(%r({|}), '').split(',').map(&:to_i).sort
          duplicates << {
            ids: ids,
            business_name: row['business_name'],
            contacts: []
          }

          contact_ids += ids
        end

        contacts = business.contacts.
          where(id: contact_ids).
          joins("LEFT JOIN account_statements ACS ON ACS.source_id = contacts.id AND ACS.source_type = '#{::Contact.name}'").
          joins("LEFT JOIN patient_contacts PC ON PC.contact_id = contacts.id").
          joins("LEFT JOIN invoices INV ON INV.invoice_to_contact_id = contacts.id AND INV.deleted_at IS NULL").
          select('contacts.id, contacts.business_name, contacts.full_name, contacts.email, contacts.phone, contacts.mobile, contacts.created_at', 'COUNT(DISTINCT ACS.id) AS account_statements_count', 'COUNT(DISTINCT PC.patient_id) AS patients_count', 'COUNT(INV.id) as invoices_count').
          group('contacts.id').
          order(id: :asc).
          to_a

        duplicates.each do |dup|
          dup[:contacts] = contacts.select do |c|
            dup[:ids].include? c.id
          end
        end

        @result[:duplicates] = duplicates
      end
    end
  end
end
