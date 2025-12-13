require "rails_helper"

RSpec.describe "Wishlist Toggle", type: :request do
  let(:owner) { create(:user) }
  let(:co_planner) { create(:user) }
  let(:viewer) { create(:user) }

  let(:event) { create(:event, user: owner) }
  let(:recipient) { create(:recipient, user: owner) }
  let(:event_recipient) { create(:event_recipient, user: owner, event: event, recipient: recipient) }
  let(:suggestion) { create(:ai_gift_suggestion, user: owner, event: event, recipient: recipient, event_recipient: event_recipient) }

  before do
    create(:collaborator, :accepted, :co_planner, event: event, user: co_planner)
    create(:collaborator, :accepted, event: event, user: viewer, role: Collaborator::ROLE_VIEWER) # should not get wishlist
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(owner)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
  end


  it "adds wishlist rows for owner + accepted co_planners/owners" do
    expect {
      post toggle_wishlist_event_ai_gift_suggestion_path(event, suggestion, from: "ai_library")
    }.to change { Wishlist.count }.by(2)

    expect(Wishlist.where(ai_gift_suggestion_id: suggestion.id).pluck(:user_id)).to match_array([owner.id, co_planner.id])
    expect(Wishlist.where(user_id: viewer.id, ai_gift_suggestion_id: suggestion.id)).to be_empty
  end

  it "removes wishlist rows for all planners if already saved" do
    [owner.id, co_planner.id].each do |uid|
      Wishlist.create!(user_id: uid, ai_gift_suggestion_id: suggestion.id, recipient_id: recipient.id)
    end

    expect {
      post toggle_wishlist_event_ai_gift_suggestion_path(event, suggestion, from: "ai_library")
    }.to change { Wishlist.where(ai_gift_suggestion_id: suggestion.id).count }.from(2).to(0)
  end
end
