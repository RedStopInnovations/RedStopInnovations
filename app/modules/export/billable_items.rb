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
          'Tax',
          'Description',
          'Creation'
        ]

        billable_items_query.load.each do |bi|
          csv << [
            bi.item_number,
            bi.name,
            bi.price,
            bi.tax.try(:name),
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
