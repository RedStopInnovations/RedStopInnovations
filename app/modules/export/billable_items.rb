module Export
  class BillableItems
    attr_reader :business

    def self.make(business)
      new(business)
    end

    def initialize(business)
      @business = business
    end

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << [
          'Item number',
          'Name',
          'Price',
          'Variable pricing',
          'Tax',
          'Rebate',
          'Description',
          'Creation'
        ]

        billable_items_query.load.each do |bi|
          variable_pricing = []
          if bi.pricing_for_contact? && bi.pricing_contacts.count > 0
            bi.pricing_contacts.each do |bic|
              next unless bic.contact.present?
              variable_pricing << "#{bic.contact.business_name}: #{bic.price}"
            end
          end
          csv << [
            bi.item_number,
            bi.name,
            bi.price,
            variable_pricing.join("\n"),
            bi.tax.try(:name),
            bi.health_insurance_rebate? ? 'Yes' : 'No',
            bi.description,
            bi.created_at.strftime('%Y-%m-%d')
          ]
        end
      end
    end

    private

    def billable_items_query
      business.billable_items.
        not_deleted.
        order(name: :asc).
        includes(:tax, pricing_contacts: [:contact])
    end
  end
end
