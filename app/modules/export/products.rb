module Export
  class Products
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
          'Name',
          'Code',
          'Price',
          'Tax',
          'Supplier name',
          'Supplier phone',
          'Supplier email',
          'Notes',
        ]

        products_query.load.each do |product|
          csv << [
            product.name,
            product.item_code,
            product.price,
            product.tax.try(:name),
            product.supplier_name.presence,
            product.supplier_phone.presence,
            product.supplier_email.presence,
            product.notes.presence,
          ]
        end
      end
    end

    private

    def products_query
      business.products.
        not_deleted.
        order(name: :asc).
        includes(:tax)
    end
  end
end
