describe Reports::TransactionsController, type: :controller, authenticated: true do
  let!(:billable_items) do
    FactoryBot.create_list(:billable_item, 10, business: current_business)
  end

  let!(:products) do
    FactoryBot.create_list(:product, 5, business: current_business)
  end
  let!(:patients) { FactoryBot.create_list(:patient, 10, business: current_business) }
  let!(:invoices) {
    15.times do
      items = []
      billable_item = billable_items.sample
      items << {
        invoiceable_id: billable_item.id,
        invoiceable_type: billable_item.class.name,
        quantity: rand(1..2),
        unit_price: billable_item.price
      }

      # Some has product
      if [true, false].sample
        product = products.sample
        items << {
          invoiceable_id: product.id,
          invoiceable_type: product.class.name,
          quantity: rand(1..2),
          unit_price: product.price
        }
      end

      Invoice.create!(
        issue_date: Date.today,
        business: current_business,
        patient: patients.sample,
        # appointment_id,
        items_attributes: items
      )
    end
  }

  let!(:payments) {
    Payment.create!(
      business: current_business,
      patient: patients.sample,
      payment_date: FFaker::Time.date,
      cash: rand(100..300)
    )
  }

  describe "GET #outstanding_invoices" do
    it 'returns 200 OK' do
      get :outstanding_invoices
      expect(response).to be_ok
    end

    describe 'CSV' do
      it 'returns 200 OK' do
        get :outstanding_invoices, params: { format: 'csv' }
        expect(response).to be_ok
      end
    end
  end

  describe "GET #invoices_raised" do
    it 'returns 200 OK' do
      get :invoices_raised
      expect(response).to be_ok
    end

    describe 'CSV' do
      it 'returns 200 OK' do
        get :invoices_raised, params: { format: 'csv' }
        expect(response).to be_ok
      end
    end
  end

  describe "GET #unsent_invoices" do
    it 'returns 200 OK' do
      get :unsent_invoices
      expect(response).to be_ok
    end

    describe 'CSV' do
      it 'returns 200 OK' do
        get :unsent_invoices, params: { format: 'csv' }
        expect(response).to be_ok
      end
    end
  end

  describe "GET #voided_invoices" do
    it 'returns 200 OK' do
      get :voided_invoices
      expect(response).to be_ok
    end

    describe 'CSV' do
      it 'returns 200 OK' do
        get :voided_invoices, params: { format: 'csv' }
        expect(response).to be_ok
      end
    end
  end

  describe "GET #payment_summary" do
    it 'returns 200 OK' do
      get :payment_summary
      expect(response).to be_ok
    end

    describe 'CSV' do
      it 'returns 200 OK' do
        get :payment_summary, params: { format: 'csv' }
        expect(response).to be_ok
      end
    end
  end
end
