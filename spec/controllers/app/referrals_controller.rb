describe App::ReferralsController, type: :controller, authenticated: true do
  describe 'GET #index' do
    before do
      referral1 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Pending'
      )

      referral1.businesses << current_business

      referral2 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Approved'
      )

      referral2.businesses << current_business

      referral3 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Rejected'
      )
    end

    it 'return OK status' do
      get :index
      expect(response).to be_ok
    end

    context 'with some search params' do
      it 'return OK status' do
        get :index, params: {
          search: 'test',
          status: 'Pending'
        }
        expect(response).to be_ok
      end
    end
  end

  describe 'GET #show' do
    context 'show a pending referral' do
      let! :referral1 do
        referral1 = FactoryBot.create(
          :referral,
          business_id: current_business.id,
          status: 'Pending'
        )

        referral1.businesses << current_business

        referral1
      end

      it 'return OK status' do
        get :show, params: {id: referral1.id }
        expect(response).to be_ok
      end
    end

    context 'show a rejected referral' do
      let! :referral1 do
        referral1 = FactoryBot.create(
          :referral,
          business_id: current_business.id,
          status: 'Rejected'
        )

        referral1.businesses << current_business

        referral1
      end

      it 'return OK status' do
        get :show, params: {id: referral1.id }
        expect(response).to be_ok
      end
    end


    context 'show a approved referral' do
      let! :referral1 do
        referral1 = FactoryBot.create(
          :referral,
          business_id: current_business.id,
          status: 'Approved'
        )

        referral1.businesses << current_business

        referral1
      end

      it 'return OK status' do
        get :show, params: {id: referral1.id }
        expect(response).to be_ok
      end
    end
  end

  describe 'GET #modal_show' do
    let! :referral1 do
      referral1 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Pending'
      )

      referral1.businesses << current_business

      referral1
    end

    it 'return OK status' do
      get :modal_show, params: {id: referral1.id }
      expect(response).to be_ok
    end
  end

  describe 'GET #new' do
    it 'return OK status' do
      get :new
      expect(response).to be_ok
    end
  end

  describe 'GET #edit' do
    let! :referral1 do
      referral1 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Pending'
      )

      referral1.businesses << current_business

      referral1
    end

    it 'return OK status' do
      get :edit, params: {id: referral1.id }
      expect(response).to be_ok
    end
  end

  describe 'PUT #approve' do
    let! :referral1 do
      referral1 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Pending'
      )

      referral1.businesses << current_business

      referral1
    end

    it 'should change referral status to Approved and create patient' do
      put :approve, params: { id: referral1.id }
      verify_referral = Referral.find referral1.id
      expect(verify_referral.status).to eq('Approved')
      expect(verify_referral.patient_id).not_to eq(nil)
    end
  end

  describe 'PUT #reject' do
    let! :referral1 do
      referral1 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Pending'
      )

      referral1.businesses << current_business

      referral1
    end

    it 'should change referral status to Rejected and store reject reason' do
      put :reject, params: {
        id: referral1.id,
        reject_reason: 'Testing'
      }
      verify_referral = Referral.find referral1.id
      expect(verify_referral.status).to eq('Rejected')
      expect(verify_referral.reject_reason).to eq('Testing')
    end
  end

  describe 'PUT #update_progress' do
    let! :referral1 do
      referral1 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Pending'
      )

      referral1.businesses << current_business

      referral1
    end

    it 'show update progress info' do
      put :update_progress, params: {
        id: referral1.id,
        referral: {
          receive_referral_date: '2020-02-02',
          summary_referral: 'A test summary'
        },
      }, format: 'html'

      verify_referral = Referral.find referral1.id
      expect(verify_referral.receive_referral_date.strftime('%Y-%m-%d')).to eq('2020-02-02')
      expect(verify_referral.summary_referral).to eq('A test summary')
    end
  end

  describe 'PUT #archive' do
    let! :referral1 do
      referral1 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Approved'
      )

      referral1.businesses << current_business

      referral1
    end

    it 'should archive the referral' do
      put :archive, params: { id: referral1.id }
      verify_referral = Referral.find referral1.id
      expect(verify_referral.archived_at).not_to eq(nil)
    end
  end

  describe 'PUT #unarchive' do
    let! :referral1 do
      referral1 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Approved',
        archived_at: 3.days.ago
      )

      referral1.businesses << current_business

      referral1
    end

    it 'should unarchive the referral' do
      put :unarchive, params: { id: referral1.id }
      verify_referral = Referral.find referral1.id
      expect(verify_referral.archived_at).to eq(nil)
    end
  end

  describe 'GET #modal_find_practitioners' do
    let! :referral1 do
      referral1 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Approved',
        archived_at: 3.days.ago
      )

      referral1.businesses << current_business

      referral1
    end

    it 'return OK status' do
      put :modal_find_practitioners, params: { id: referral1.id }
      expect(response).to be_ok
    end
  end

  describe 'PUT #update_internal_note' do
    let! :referral1 do
      referral1 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Pending'
      )

      referral1.businesses << current_business

      referral1
    end

    it 'should update the note and return OK status' do
      put :update_internal_note, params: { id: referral1.id, internal_note: 'A test note' }
      expect(response).to be_ok
      verify_referral = Referral.find referral1.id
      expect(verify_referral.internal_note).to eq('A test note')
    end
  end

  describe 'GET #find_first_appointment' do
    let! :referral1 do
      referral1 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Approved',
        archived_at: 3.days.ago
      )

      referral1.businesses << current_business

      referral1
    end

    it 'return OK status' do
      put :find_first_appointment, params: { id: referral1.id }
      expect(response).to be_ok
    end
  end

  describe 'GET #modal_reject_confirmation' do
    let! :referral1 do
      referral1 = FactoryBot.create(
        :referral,
        business_id: current_business.id,
        status: 'Pending'
      )

      referral1.businesses << current_business

      referral1
    end

    it 'return OK status' do
      put :modal_reject_confirmation, params: { id: referral1.id }
      expect(response).to be_ok
    end
  end

  describe 'PUT #assign_practitioner' do
    # @TODO: add test
  end

  describe 'POST #create' do
    # @TODO: add test
  end

  describe 'PUT #update' do
    # @TODO: add test
  end
end

