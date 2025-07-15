describe InvoicesController, type: :controller, authenticated: true do
  let!(:patient_1) { FactoryBot.create(:patient, business: current_business) }
  let!(:tax_1) { FactoryBot.create(:tax, business: current_business, rate: 10) }
  let!(:billable_item_1) { FactoryBot.create(:billable_item, business: current_business) }
  let!(:billable_item_2) { FactoryBot.create(:billable_item, business: current_business, tax: tax_1) }
  let!(:product_1) { FactoryBot.create(:product, business: current_business) }
  let!(:case_type_1) { FactoryBot.create(:case_type, business: current_business) }

  describe 'GET #index' do
    it 'return 200 OK' do
      get :index
      expect(response).to be_ok
    end
  end

  describe 'GET #show' do
    context 'general invoice' do

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

      it 'return 200 OK' do
        get :show, params: { id: invoice_1.id }
        expect(response).to be_ok
      end
    end

    context 'appointment invoice' do
      let! :practitioner_1 do
        user = FactoryBot.create :user, :as_practitioner, business: current_business
        user.practitioner
      end

      let!(:home_visit_appointment_type1) do
        FactoryBot.create(:appointment_type, :home_visit, business: current_business)
      end

      let!(:appointment_1) {
        avail_1 = FactoryBot.create(
          :availability,
          :type_home_visit,
          practitioner: practitioner_1,
          start_time: '2022-01-01 08:00',
          end_time: '2022-01-01 11:30',
          business: current_business
        )

        appt = FactoryBot.create(
          :appointment,
          practitioner: practitioner_1,
          patient: patient_1,
          availability: avail_1,
          appointment_type: home_visit_appointment_type1,
          start_time: avail_1.start_time,
          end_time: avail_1.end_time
        )
      }

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
        invoice.appointment_id = appointment_1.id
        invoice.service_date = appointment_1.start_time.to_date
        invoice.practitioner_id = practitioner_1.id

        invoice.save!(validate: false)

        invoice
      }

      it 'return 200 OK' do
        get :show, params: { id: invoice_1.id }
        expect(response).to be_ok
      end
    end

    # @TODO: task invoice
  end

  describe 'POST #create' do
    context 'Params invalid' do
      context 'with no patient specified' do
        it 'does not create invoice and render #new template' do
          expect {
            post :create, params: {
              invoice: {
                patient_id: nil,
                appointment_id: nil,
                patient_case_id: nil,
                invoice_to_contact_id: nil,
                items_attributes: {
                  "0" => {
                    "invoiceable_type" => billable_item_1.class,
                    "invoiceable_id" => billable_item_1.id,
                    "quantity" => 1,
                    "unit_price" => 100
                  }
                }
              }
            }
          }.to_not change { Invoice.count }
          expect(response).to render_template(:new)
        end
      end

      # TODO: make this case pass
      # context 'with no items' do
      #   it 'does not create invoice and render :new template' do
      #     expect {
      #       post :create, params: {
      #         invoice: {
      #           patient_id: patient_1.id,
      #           appointment_id: nil,
      #           patient_case_id: nil,
      #           invoice_to_contact_id: nil
      #         }
      #       }
      #     }.to_not change { Invoice.count }
      #     expect(response).to render_template(:new)
      #   end
      # end
    end

    context 'Params valid' do
      context 'as a general invoice' do
        it 'create the invoice' do
          expect {
            post :create, params: {
              invoice: {
                patient_id: patient_1.id,
                appointment_id: nil,
                patient_case_id: nil,
                invoice_to_contact_id: nil,
                items_attributes: {
                  "0" => {
                    "invoiceable_type" => billable_item_1.class,
                    "invoiceable_id" => billable_item_1.id,
                    "quantity" => 1,
                    "unit_price" => 100
                  },
                  "1" => {
                    "invoiceable_type" => product_1.class,
                    "invoiceable_id" => product_1.id,
                    "quantity" => 1,
                    "unit_price" => 50
                  }
                }
              }
            }
          }.to change { Invoice.count }.by(1)
          created_invoice = Invoice.order(id: :desc).first
          expect(created_invoice.amount).to eq(150)
          expect(created_invoice.items.count).to eq(2)
          expect(response).to have_http_status(302)
        end
      end

      context 'with items has taxes' do
        it 'create the invoice with amounts calculated correctly' do
          expect {
            post :create, params: {
              invoice: {
                patient_id: patient_1.id,
                appointment_id: nil,
                patient_case_id: nil,
                invoice_to_contact_id: nil,
                items_attributes: {
                  "0" => {
                    "invoiceable_type" => billable_item_1.class,
                    "invoiceable_id" => billable_item_1.id,
                    "quantity" => 1,
                    "unit_price" => 100
                  },
                  "1" => {
                    "invoiceable_type" => billable_item_2.class,
                    "invoiceable_id" => billable_item_2.id,
                    "quantity" => 1,
                    "unit_price" => 100
                  }
                }
              }
            }
          }.to change { Invoice.count }.by(1)
          created_invoice = Invoice.order(id: :desc).first
          expect(created_invoice.items.count).to eq(2)
          expect(created_invoice.amount).to eq(210)
          expect(created_invoice.amount_ex_tax).to eq(200)

          # Check invoice items created
          billable_item_1_line_item = created_invoice.items.where(invoiceable: billable_item_1).first
          expect(billable_item_1_line_item.unit_name).to eq(billable_item_1.name)
          expect(billable_item_1_line_item.tax_name).to be_nil
          expect(billable_item_1_line_item.tax_rate).to be_nil
          expect(billable_item_1_line_item.amount).to eq(100)

          billable_item_2_line_item = created_invoice.items.where(invoiceable: billable_item_2).first
          expect(billable_item_2_line_item.unit_name).to eq(billable_item_2.name)
          expect(billable_item_2_line_item.tax_name).to eq(billable_item_2.tax_name)
          expect(billable_item_2_line_item.tax_rate).to eq(billable_item_2.tax_rate)
          expect(billable_item_2_line_item.amount).to eq(110)

          expect(response).to have_http_status(302)
        end
      end

      context 'issued for appointment' do
        let! :practitioner_1 do
          user = FactoryBot.create :user, :as_practitioner, business: current_business
          user.practitioner
        end

        let!(:home_visit_appointment_type1) do
          FactoryBot.create(:appointment_type, :home_visit, business: current_business)
        end

        let!(:appointment_1) {
          avail_1 = FactoryBot.create(
            :availability,
            :type_home_visit,
            practitioner: practitioner_1,
            start_time: '2022-01-01 08:00',
            end_time: '2022-01-01 11:30',
            business: current_business
          )

          appt = FactoryBot.create(
            :appointment,
            practitioner: practitioner_1,
            patient: patient_1,
            availability: avail_1,
            appointment_type: home_visit_appointment_type1,
            start_time: avail_1.start_time,
            end_time: avail_1.end_time
          )
        }

        it 'create invoice have associated appointment' do
          expect {
            post :create, params: {
              invoice: {
                patient_id: patient_1.id,
                appointment_id: appointment_1.id,
                patient_case_id: nil,
                invoice_to_contact_id: nil,
                items_attributes: {
                  "0" => {
                    "invoiceable_type" => billable_item_1.class,
                    "invoiceable_id" => billable_item_1.id,
                    "quantity" => 1,
                    "unit_price" => 100
                  }
                }
              }
            }
          }.to change { Invoice.count }.by(1)
          created_invoice = Invoice.order(id: :desc).first
          expect(created_invoice.amount).to eq(100)
          expect(created_invoice.items.count).to eq(1)
          expect(created_invoice.appointment_id).to eq(appointment_1.id)
          expect(response).to have_http_status(302)
        end
      end

      context 'issued for task' do
        let! :practitioner_1 do
          user = FactoryBot.create :user, :as_practitioner, business: current_business
          user.practitioner
        end

        let!(:task_1) do
          task = FactoryBot.create(:task, patient_id: patient_1.id, business: current_business, owner: current_user)
          task.task_users.first.update_columns(complete_at: Time.current, status: 'Complete', completion_duration: 15)
          task
        end

        it 'create invoice have associated task' do
          expect {
            post :create, params: {
              invoice: {
                patient_id: patient_1.id,
                task_id: task_1.id,
                items_attributes: {
                  "0" => {
                    "invoiceable_type" => billable_item_1.class,
                    "invoiceable_id" => billable_item_1.id,
                    "quantity" => 1,
                    "unit_price" => 100
                  }
                }
              }
            }
          }.to change { Invoice.count }.by(1)
          created_invoice = Invoice.order(id: :desc).first
          expect(created_invoice.amount).to eq(100)
          expect(created_invoice.items.count).to eq(1)
          expect(created_invoice.task_id).to eq(task_1.id)
          expect(response).to have_http_status(302)
        end
      end

      context 'associate with a case' do
        let! :case_1 do
          FactoryBot.create :patient_case, patient: patient_1, case_type: case_type_1
        end

        it 'create invoice have associated case' do
          expect {
            post :create, params: {
              invoice: {
                patient_id: patient_1.id,
                patient_case_id: case_1.id,
                items_attributes: {
                  "0" => {
                    "invoiceable_type" => billable_item_1.class,
                    "invoiceable_id" => billable_item_1.id,
                    "quantity" => 1,
                    "unit_price" => 100
                  }
                }
              }
            }
          }.to change { Invoice.count }.by(1)
          created_invoice = Invoice.order(id: :desc).first
          expect(created_invoice.amount).to eq(100)
          expect(created_invoice.items.count).to eq(1)
          expect(created_invoice.patient_case_id).to eq(case_1.id)
          expect(response).to have_http_status(302)
        end
      end

      context 'issue to a contact' do
        let! :contact_1 do
          FactoryBot.create :contact, business: current_business
        end

        it 'create invoice have associated invoice to contact' do
          expect {
            post :create, params: {
              invoice: {
                patient_id: patient_1.id,
                invoice_to_contact_id: contact_1.id,
                items_attributes: {
                  "0" => {
                    "invoiceable_type" => billable_item_1.class,
                    "invoiceable_id" => billable_item_1.id,
                    "quantity" => 1,
                    "unit_price" => 100
                  }
                }
              }
            }
          }.to change { Invoice.count }.by(1)
          created_invoice = Invoice.order(id: :desc).first
          expect(created_invoice.amount).to eq(100)
          expect(created_invoice.items.count).to eq(1)
          expect(created_invoice.invoice_to_contact_id).to eq(contact_1.id)
          expect(response).to have_http_status(302)
        end
      end
    end
  end

  describe 'PUT #update' do
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

    context 'Params invalid' do
      context 'with no patient specified' do
        it 'does not update invoice and render #edit template' do
          expect {
            put :update, params: {
              id: invoice_1.id,
              invoice: {
                patient_id: nil,
                appointment_id: nil,
                items_attributes: {
                  "0" => {
                    "invoiceable_type" => billable_item_1.class,
                    "invoiceable_id" => billable_item_1.id,
                    "quantity" => 1,
                    "unit_price" => 50
                  }
                }
              }
            }
          }.to_not change { invoice_1.amount }
        end
      end
    end

    context 'Params valid' do
      context 'with simple invoice' do
        it 'update the invoice' do
          update_items_params = {}

          # Existing items
          invoice_1.items.each do |ii|
            update_items_params[ii.id.to_s] = {
              "id" => ii.id,
              "invoiceable_type" => ii.invoiceable_type,
              "invoiceable_id" => ii.invoiceable_id,
              "quantity" => ii.quantity,
              "unit_price" => ii.unit_price
            }
          end

          # Add new items
          update_items_params[rand(1000..10000000).to_s] = {
            "invoiceable_type" => product_1.class,
            "invoiceable_id" => product_1.id,
            "quantity" => 1,
            "unit_price" => 50
          }

          put :update, params: {
            id: invoice_1.id,
            invoice: {
              patient_id: patient_1.id,
              appointment_id: nil,
              patient_case_id: nil,
              invoice_to_contact_id: nil,
              items_attributes: update_items_params
            }
          }
          updated_invoice = Invoice.find(invoice_1.id)
          expect(updated_invoice.amount).to eq(150)
          expect(updated_invoice.items.count).to eq(2)
          expect(response).to have_http_status(302)
        end
      end

      context 'with items has taxes' do
        it 'update the invoice with amounts calculated correctly' do
          update_items_params = {}

          # Existing items
          invoice_1.items.each do |ii|
            update_items_params[ii.id.to_s] = {
              "id" => ii.id,
              "invoiceable_type" => ii.invoiceable_type,
              "invoiceable_id" => ii.invoiceable_id,
              "quantity" => ii.quantity,
              "unit_price" => ii.unit_price
            }
          end

          # Add new items
          update_items_params[rand(1000..10000000).to_s] = {
            "invoiceable_type" => billable_item_2.class,
            "invoiceable_id" => billable_item_2.id,
            "quantity" => 1,
            "unit_price" => 100 # This one has 10% tax
          }

          put :update, params: {
            id: invoice_1.id,
            invoice: {
              patient_id: patient_1.id,
              appointment_id: nil,
              patient_case_id: nil,
              invoice_to_contact_id: nil,
              items_attributes: update_items_params
            }
          }

          updated_invoice = Invoice.find(invoice_1.id)
          expect(updated_invoice.items.count).to eq(2)
          expect(updated_invoice.amount).to eq(210)
          expect(updated_invoice.amount_ex_tax).to eq(200)

          expect(response).to have_http_status(302)
        end
      end

      context "delete some items" do
        it 'update the invoice with amounts calculated correctly' do
          update_items_params = {}

          # Delete existing items
          invoice_1.items.each do |ii|
            update_items_params[ii.id.to_s] = {
              "id" => ii.id,
              "invoiceable_type" => ii.invoiceable_type,
              "invoiceable_id" => ii.invoiceable_id,
              "quantity" => ii.quantity,
              "unit_price" => ii.unit_price,
              "_destroy" => true
            }
          end

          # Add new items
          update_items_params[rand(1000..10000000).to_s] = {
            "invoiceable_type" => billable_item_2.class,
            "invoiceable_id" => billable_item_2.id,
            "quantity" => 1,
            "unit_price" => 100
          }

          update_items_params[rand(1000..10000000).to_s] = {
            "invoiceable_type" => product_1.class,
            "invoiceable_id" => product_1.id,
            "quantity" => 1,
            "unit_price" => 20
          }

          put :update, params: {
            id: invoice_1.id,
            invoice: {
              patient_id: patient_1.id,
              appointment_id: nil,
              patient_case_id: nil,
              invoice_to_contact_id: nil,
              items_attributes: update_items_params
            }
          }

          updated_invoice = Invoice.find(invoice_1.id)
          expect(updated_invoice.items.count).to eq(2)
          expect(updated_invoice.amount).to eq(130)
          expect(updated_invoice.amount_ex_tax).to eq(120)

          expect(response).to have_http_status(302)
        end
      end
    end
  end
end