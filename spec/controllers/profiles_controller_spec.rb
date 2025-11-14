require 'rails_helper'

RSpec.describe ProfilesController, type: :controller do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'Password1!') }

  describe 'GET #edit' do
    context 'when user is logged in' do
      before do
        session[:user_id] = user.id
      end

      it 'returns http success' do
        get :edit
        expect(response).to have_http_status(:success)
      end

      it 'renders the edit template' do
        get :edit
        expect(response).to render_template(:edit)
      end

      it 'assigns @user' do
        get :edit
        expect(assigns(:user)).to eq(user)
      end
    end

    context 'when user is not logged in' do
      it 'redirects to login page' do
        get :edit
        expect(response).to redirect_to(login_path)
      end

      it 'sets an alert flash message' do
        get :edit
        expect(flash[:alert]).to eq('Please log in to continue')
      end
    end
  end

  describe 'PATCH #update' do
    context 'when user is logged in' do
      before do
        session[:user_id] = user.id
      end

      context 'with valid attributes' do
        let(:valid_attributes) do
          { user: { name: 'Updated Name', email: 'updated@example.com' } }
        end

        it 'updates the user' do
          patch :update, params: valid_attributes
          user.reload
          expect(user.name).to eq('Updated Name')
          expect(user.email).to eq('updated@example.com')
        end

        it 'redirects to dashboard' do
          patch :update, params: valid_attributes
          expect(response).to redirect_to(dashboard_path)
        end

        it 'sets a success notice' do
          patch :update, params: valid_attributes
          expect(flash[:notice]).to eq('Profile updated successfully')
        end
      end

      context 'with optional fields' do
        let(:optional_attributes) do
          {
            user: {
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

        it 'updates optional fields' do
          patch :update, params: optional_attributes
          user.reload
          expect(user.date_of_birth).to eq(Date.new(1990, 1, 1))
          expect(user.phone_number).to eq('(123) 456-7890')
          expect(user.gender).to eq('Male')
          expect(user.occupation).to eq('Developer')
          expect(user.hobbies).to eq('Coding')
          expect(user.likes).to eq('Coffee')
          expect(user.dislikes).to eq('Bugs')
        end
      end

      context 'with password change' do
        let(:password_attributes) do
          { user: { password: 'NewPass1!', password_confirmation: 'NewPass1!' } }
        end

        it 'updates the password' do
          patch :update, params: password_attributes
          user.reload
          expect(user.authenticate('NewPass1!')).to eq(user)
        end
      end

      context 'with blank password fields' do
        let(:blank_password_attributes) do
          { user: { name: 'Name Change', password: '', password_confirmation: '' } }
        end

        it 'does not change the password' do
          patch :update, params: blank_password_attributes
          user.reload
          expect(user.authenticate('Password1!')).to eq(user)
        end

        it 'updates other fields' do
          patch :update, params: blank_password_attributes
          user.reload
          expect(user.name).to eq('Name Change')
        end
      end

      context 'with invalid attributes' do
        let(:invalid_attributes) do
          { user: { name: '', email: 'invalidemail' } }
        end

        it 'does not update the user' do
          original_name = user.name
          patch :update, params: invalid_attributes
          user.reload
          expect(user.name).to eq(original_name)
        end

        it 'renders edit template' do
          patch :update, params: invalid_attributes
          expect(response).to render_template(:edit)
        end

        it 'returns unprocessable_content status' do
          patch :update, params: invalid_attributes
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context 'with mismatched password confirmation' do
        let(:mismatched_passwords) do
          { user: { password: 'NewPass1!', password_confirmation: 'Different1!' } }
        end

        it 'does not update the password' do
          patch :update, params: mismatched_passwords
          user.reload
          expect(user.authenticate('Password1!')).to eq(user)
        end

        it 'renders edit template with errors' do
          patch :update, params: mismatched_passwords
          expect(response).to render_template(:edit)
        end
      end

      context 'with invalid phone number' do
        let(:invalid_phone) do
          { user: { phone_number: '123' } }
        end

        it 'does not update phone number' do
          patch :update, params: invalid_phone
          expect(response).to render_template(:edit)
        end
      end

      context 'with invalid gender' do
        let(:invalid_gender) do
          { user: { gender: 'InvalidGender' } }
        end

        it 'does not update gender' do
          patch :update, params: invalid_gender
          expect(response).to render_template(:edit)
        end
      end

      context 'with future date of birth' do
        let(:future_dob) do
          { user: { date_of_birth: Date.today + 1.day } }
        end

        it 'does not update date of birth' do
          patch :update, params: future_dob
          expect(response).to render_template(:edit)
        end
      end
    end

    context 'when user is not logged in' do
      it 'redirects to login page' do
        patch :update, params: { user: { name: 'New Name' } }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end