require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    let(:user) do
      User.create!(
        name: 'Test User',
        email: 'test@example.com',
        password: 'Password1!'
      )
    end

    context 'with valid credentials' do
      it 'logs in the user' do
        post :create, params: { email: user.email, password: 'Password1!' }
        expect(session[:user_id]).to eq(user.id)
      end

      it 'redirects to dashboard' do
        post :create, params: { email: user.email, password: 'Password1!' }
        expect(response).to redirect_to(dashboard_path)
      end

      it 'sets a success notice' do
        post :create, params: { email: user.email, password: 'Password1!' }
        expect(flash[:notice]).to eq("Welcome back, #{user.name}!")
      end

      it 'is case insensitive for email' do
        post :create, params: { email: user.email.upcase, password: 'Password1!' }
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context 'with invalid credentials' do
      it 'does not log in with wrong email' do
        post :create, params: { email: 'wrong@example.com', password: 'Password1!' }
        expect(session[:user_id]).to be_nil
      end

      it 'does not log in with wrong password' do
        post :create, params: { email: user.email, password: 'wrongpassword' }
        expect(session[:user_id]).to be_nil
      end

      it 'renders the new template with wrong credentials' do
        post :create, params: { email: user.email, password: 'wrongpassword' }
        expect(response).to render_template(:new)
      end

      it 'sets an error alert with wrong credentials' do
        post :create, params: { email: user.email, password: 'wrongpassword' }
        expect(flash[:alert]).to eq('Invalid email or password')
      end

      it 'returns unprocessable entity status with wrong credentials' do
        post :create, params: { email: user.email, password: 'wrongpassword' }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when user is OAuth-only user' do
      let(:oauth_user) do
        user = User.new(name: 'OAuth User', email: 'oauth@example.com')
        user.skip_password_validation = true
        user.save!
        user.authentications.create!(provider: 'google_oauth2', uid: '123', email: 'oauth@example.com', name: 'OAuth User')
        user
      end

      it 'does not allow login with password' do
        post :create, params: { email: oauth_user.email, password: 'anypassword' }
        expect(session[:user_id]).to be_nil
      end

      it 'shows appropriate error message' do
        post :create, params: { email: oauth_user.email, password: 'anypassword' }
        expect(flash[:alert]).to include('created with Google')
      end

      it 'renders login template' do
        post :create, params: { email: oauth_user.email, password: 'anypassword' }
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'GET #omniauth' do
    before do
      request.env['omniauth.auth'] = OmniAuth::AuthHash.new({
                                                              provider: 'google_oauth2',
                                                              uid: '123456',
                                                              info: {
                                                                email: 'oauth@example.com',
                                                                name: 'OAuth User'
                                                              }
                                                            })
    end

    context 'with new user' do
      it 'creates a new user' do
        expect {
          get :omniauth, params: { provider: 'google_oauth2' }
        }.to change(User, :count).by(1)
      end

      it 'creates authentication record' do
        expect {
          get :omniauth, params: { provider: 'google_oauth2' }
        }.to change(Authentication, :count).by(1)
      end

      it 'logs in the user' do
        get :omniauth, params: { provider: 'google_oauth2' }
        expect(session[:user_id]).not_to be_nil
      end

      it 'redirects to dashboard' do
        get :omniauth, params: { provider: 'google_oauth2' }
        expect(response).to redirect_to(dashboard_path)
      end

      it 'sets welcome notice' do
        get :omniauth, params: { provider: 'google_oauth2' }
        expect(flash[:notice]).to eq('Welcome, OAuth User!')
      end
    end

    context 'with existing user' do
      let!(:existing_user) do
        User.create!(name: 'Existing', email: 'oauth@example.com', password: 'Password1!')
      end

      it 'does not create new user' do
        expect {
          get :omniauth, params: { provider: 'google_oauth2' }
        }.not_to change(User, :count)
      end

      it 'creates authentication for existing user' do
        expect {
          get :omniauth, params: { provider: 'google_oauth2' }
        }.to change(Authentication, :count).by(1)
      end

      it 'logs in existing user' do
        get :omniauth, params: { provider: 'google_oauth2' }
        expect(session[:user_id]).to eq(existing_user.id)
      end

      it 'redirects to dashboard' do
        get :omniauth, params: { provider: 'google_oauth2' }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'with returning OAuth user' do
      let!(:oauth_user) do
        user = User.new(name: 'OAuth', email: 'oauth@example.com')
        user.skip_password_validation = true
        user.save!
        user.authentications.create!(provider: 'google_oauth2', uid: '123456', email: 'oauth@example.com', name: 'OAuth')
        user
      end

      it 'does not create duplicate user' do
        expect {
          get :omniauth, params: { provider: 'google_oauth2' }
        }.not_to change(User, :count)
      end

      it 'does not create duplicate authentication' do
        expect {
          get :omniauth, params: { provider: 'google_oauth2' }
        }.not_to change(Authentication, :count)
      end

      it 'logs in the user' do
        get :omniauth, params: { provider: 'google_oauth2' }
        expect(session[:user_id]).to eq(oauth_user.id)
      end
    end

    context 'when authentication fails' do
      before do
        allow(User).to receive(:from_omniauth).and_return(nil)
      end

      it 'redirects to login page' do
        get :omniauth, params: { provider: 'google_oauth2' }
        expect(response).to redirect_to(login_path)
      end

      it 'sets error alert' do
        get :omniauth, params: { provider: 'google_oauth2' }
        expect(flash[:alert]).to eq('Authentication failed. Please try again.')
      end

      it 'does not log in user' do
        get :omniauth, params: { provider: 'google_oauth2' }
        expect(session[:user_id]).to be_nil
      end
    end
  end

  describe 'GET #auth_failure' do
    it 'redirects to login page' do
      get :auth_failure
      expect(response).to redirect_to(login_path)
    end

    it 'sets error alert' do
      get :auth_failure
      expect(flash[:alert]).to eq('Authentication failed. Please try again.')
    end
  end

  describe 'DELETE #destroy' do
    let(:user) do
      User.create!(
        name: 'Test User',
        email: 'test@example.com',
        password: 'Password1!'
      )
    end

    before do
      session[:user_id] = user.id
    end

    it 'logs out the user' do
      delete :destroy
      expect(session[:user_id]).to be_nil
    end

    it 'redirects to root path' do
      delete :destroy
      expect(response).to redirect_to(root_path)
    end

    it 'sets a logout notice' do
      delete :destroy
      expect(flash[:notice]).to eq('You have been logged out successfully')
    end
  end
end