require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  describe 'GET #new' do
    it 'returns a successful response' do
      get :new
      expect(response).to be_successful
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    let!(:user) do
      User.create!(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123'
      )
    end

    context 'with valid credentials' do
      it 'logs in the user' do
        post :create, params: { email: 'test@example.com', password: 'password123' }
        expect(session[:user_id]).to eq(user.id)
      end

      it 'redirects to dashboard' do
        post :create, params: { email: 'test@example.com', password: 'password123' }
        expect(response).to redirect_to(dashboard_path)
      end

      it 'sets a success notice' do
        post :create, params: { email: 'test@example.com', password: 'password123' }
        expect(flash[:notice]).to eq("Welcome back, Test User!")
      end

      it 'is case insensitive for email' do
        post :create, params: { email: 'TEST@EXAMPLE.COM', password: 'password123' }
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context 'with invalid credentials' do
      it 'does not log in with wrong email' do
        post :create, params: { email: 'wrong@example.com', password: 'password123' }
        expect(session[:user_id]).to be_nil
      end

      it 'does not log in with wrong password' do
        post :create, params: { email: 'test@example.com', password: 'wrongpassword' }
        expect(session[:user_id]).to be_nil
      end

      it 'renders the new template with wrong credentials' do
        post :create, params: { email: 'wrong@example.com', password: 'password123' }
        expect(response).to render_template(:new)
      end

      it 'sets an error alert with wrong credentials' do
        post :create, params: { email: 'wrong@example.com', password: 'password123' }
        expect(flash[:alert]).to eq('Invalid email or password')
      end

      it 'returns unprocessable entity status with wrong credentials' do
        post :create, params: { email: 'wrong@example.com', password: 'password123' }
        expect(response.status).to eq(422)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:user) do
      User.create!(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123'
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
      expect(flash[:notice]).to eq('You have been logged out')
    end
  end
end