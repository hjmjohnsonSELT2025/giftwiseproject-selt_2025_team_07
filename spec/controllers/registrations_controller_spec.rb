require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
    end

    it 'assigns a new user' do
      get :new
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      let(:valid_attributes) do
        {
          user: {
            name: 'Test User',
            email: 'test@example.com',
            password: 'Password1!'
          }
        }
      end

      it 'creates a new user' do
        expect {
          post :create, params: valid_attributes
        }.to change(User, :count).by(1)
      end

      it 'logs in the user' do
        post :create, params: valid_attributes
        expect(session[:user_id]).to eq(User.last.id)
      end

      it 'redirects to dashboard' do
        post :create, params: valid_attributes
        expect(response).to redirect_to(dashboard_path)
      end

      it 'sets a welcome notice' do
        post :create, params: valid_attributes
        expect(flash[:notice]).to eq("Welcome to GiftWise, Test User!")
      end
    end

    context 'with optional fields' do
      let(:full_attributes) do
        {
          user: {
            name: 'Test User',
            email: 'test@example.com',
            password: 'Password1!',
            date_of_birth: Date.new(1990, 1, 1),
            phone_number: '(123) 456-7890',
            gender: 'Male',
            occupation: 'Developer',
            hobbies: 'Coding',
            likes: 'Coffee',
            dislikes: 'Bugs'
          }
        }
      end

      it 'creates user with all fields' do
        post :create, params: full_attributes
        user = User.last
        expect(user.date_of_birth).to eq(Date.new(1990, 1, 1))
        expect(user.phone_number).to eq('(123) 456-7890')
        expect(user.gender).to eq('Male')
        expect(user.occupation).to eq('Developer')
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) do
        {
          user: {
            name: '',
            email: 'invalid',
            password: 'weak'
          }
        }
      end

      it 'does not create a new user' do
        expect {
          post :create, params: invalid_attributes
        }.not_to change(User, :count)
      end

      it 'renders the new template' do
        post :create, params: invalid_attributes
        expect(response).to render_template(:new)
      end

      it 'returns unprocessable_content status' do
        post :create, params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end