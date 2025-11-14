require 'rails_helper'

RSpec.describe 'Profile routes', type: :routing do
  it 'routes GET /profile/edit to profiles#edit' do
    expect(get: '/profile/edit').to route_to('profiles#edit')
  end

  it 'routes PATCH /profile to profiles#update' do
    expect(patch: '/profile').to route_to('profiles#update')
  end

  it 'routes PUT /profile to profiles#update' do
    expect(put: '/profile').to route_to('profiles#update')
  end

  it 'generates edit_profile_path' do
    expect(edit_profile_path).to eq('/profile/edit')
  end

  it 'generates profile_path' do
    expect(profile_path).to eq('/profile')
  end
end