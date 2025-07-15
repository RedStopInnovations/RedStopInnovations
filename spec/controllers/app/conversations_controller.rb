describe App::ConversationsController, type: :controller, authenticated: true do
  describe 'POST #create' do
    context 'Params Valid' do
      it 'return redirect to dashboard' do
        post :create, { url: "/posts/1", content: 'Curabitur arcu erat', redirect: '/app/patients'}
        expect(response).to redirect_to('/app/patients')
      end

      it 'return redirect to default url' do
        post :create, { url: "/posts/1", content: 'Curabitur arcu erat'}
        expect(flash[:notice]).to redirect_to(dashboard_path)
      end

      it 'return flash notice' do
        post :create, { url: "/posts/1", content: 'Curabitur arcu erat', redirect: '/app/dashboard'}
        expect(flash[:notice]).to be_a(String)
      end
    end

    context 'Params Invalid' do
      it 'return flash alert params #url nil' do
        post :create, {content: 'Curabitur arcu erat'}
        expect(flash[:alert]).to be_a(String)
      end

      it 'return flash alert params #content nil' do
        post :create, {}
        expect(flash[:alert]).to be_a(String)
      end
    end
  end
end