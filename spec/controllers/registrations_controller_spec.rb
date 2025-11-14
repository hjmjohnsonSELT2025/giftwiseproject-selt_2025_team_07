require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  describe 'GET #new' do
    it 'returns a successful response' do
      get :new
      expect(response).to be_successful
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
    context 'with valid parameters' do
      let(:valid_params) do
        {
          user: {
            name: 'New User',
            email: 'newuser@example.com',
            password: 'password123'
          }
        }
      end

      it 'creates a new user' do
        expect {
          post :create, params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'logs in the new user' do
        post :create, params: valid_params
        expect(session[:user_id]).to eq(User.last.id)
      end

      it 'redirects to dashboard' do
        post :create, params: valid_params
        expect(response).to redirect_to(dashboard_path)
      end

      it 'sets a welcome notice' do
        post :create, params: valid_params
        expect(flash[:notice]).to eq('Welcome to GiftWise, New User!')
      end
    end

    context 'with optional profile information' do
      let(:params_with_profile) do
        {
          user: {
            name: 'Profile User',
            email: 'profile@example.com',
            password: 'password123',
            age: 28,
            occupation: 'Engineer',
            hobbies: 'Reading, Hiking',
            likes: 'Coffee',
            dislikes: 'Spam'
          }
        }
      end

      it 'creates user with profile information' do
        post :create, params: params_with_profile
        user = User.last
        expect(user.age).to eq(28)
        expect(user.occupation).to eq('Engineer')
        expect(user.hobbies).to eq('Reading, Hiking')
        expect(user.likes).to eq('Coffee')
        expect(user.dislikes).to eq('Spam')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          user: {
            name: '',
            email: 'invalid',
            password: 'short'
          }
        }
      end

      it 'does not create a new user' do
        expect {
          post :create, params: invalid_params
        }.not_to change(User, :count)
      end

      it 'renders the new template' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end

      it 'returns unprocessable entity status' do
        post :create, params: invalid_params
        expect(response.status).to eq(422)
      end

      it 'assigns the user with errors' do
        post :create, params: invalid_params
        expect(assigns(:user).errors).not_to be_empty
      end
    end

    context 'with duplicate email' do
      before do
        User.create!(
          name: 'Existing User',
          email: 'existing@example.com',
          password: 'password123'
        )
      end

      let(:duplicate_params) do
        {
          user: {
            name: 'New User',
            email: 'existing@example.com',
            password: 'password123'
          }
        }
      end

      it 'does not create a user' do
        expect {
          post :create, params: duplicate_params
        }.not_to change(User, :count)
      end

      it 'shows email uniqueness error' do
        post :create, params: duplicate_params
        expect(assigns(:user).errors[:email]).to include('has already been taken')
      end
    end
  end
end