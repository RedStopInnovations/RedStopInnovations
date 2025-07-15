describe PaymentsController, type: :controller, authenticated: true do
  describe 'POST #bulk_create' do
    let!(:patient_1) { FactoryBot.create(:patient, business: current_business) }
    let!(:patient_2) { FactoryBot.create(:patient, business: current_business) }
    let!(:billable_item_1) { FactoryBot.create(:billable_item, business: current_business) }
    let!(:billable_item_2) { FactoryBot.create(:billable_item, business: current_business) }

    let!(:invoice_1) {
      invoice = Invoice.new(
        patient_id: patient_1.id,
        business_id: current_business.id,
        invoice_number: '000011',
        issue_date: Date.today
      )

      invoice.items.new(
        invoiceable: billable_item_1,
        quantity: 1,
        unit_price: 100,
        unit_name: billable_item_1.name
      )

      invoice.amount = 100
      invoice.amount_ex_tax = 100
      invoice.outstanding = 100

      invoice.save!(validate: false)

      invoice
    }

    let!(:invoice_2) {
      invoice = Invoice.new(
        patient_id: patient_2.id,
        business_id: current_business.id,
        invoice_number: '000012',
        issue_date: Date.today
      )

      invoice.items.new(
        invoiceable: billable_item_2,
        quantity: 1,
        unit_price: 50,
        unit_name: billable_item_2.name
      )

      invoice.amount = 50
      invoice.amount_ex_tax = 50
      invoice.outstanding = 50

      invoice.save!(validate: false)

      invoice
    }

    context 'with invalid params' do
      it 'should return 422 status with validation errors' do
        expect {
          put :bulk_create, params: {
            payments: [
              {
                invoice_id: invoice_1.id,
                payment_date: nil,
                payment_method: 'Cash',
              },
              {
                invoice_id: invoice_2.id,
                payment_date: Date.today.strftime('%Y-%m-%d'),
                payment_method: 'Invalid payment method',
              }
            ]
          }
        }.to_not change { Payment.count }

        expect(response).to have_http_status(422)
        expect(Invoice.find(invoice_1.id).outstanding).to eq(100)
        expect(Invoice.find(invoice_2.id).outstanding).to eq(50)
      end
    end

    context 'with valid params' do
      it 'should create payments and make invoices paid' do
        expect {
          put :bulk_create, params: {
            payments: [
              {
                invoice_id: invoice_1.id,
                payment_date: Date.today.strftime('%Y-%m-%d'),
                payment_method: 'Direct deposit',
              },
              {
                invoice_id: invoice_2.id,
                payment_date: Date.today.strftime('%Y-%m-%d'),
                payment_method: 'Cash',
              }
            ]
          }
        }.to change { Payment.count }.by(2)

        expect(response).to have_http_status(201)
        expect(Invoice.find(invoice_1.id).outstanding).to eq(0)
        expect(Invoice.find(invoice_2.id).outstanding).to eq(0)
      end
    end
  end
end