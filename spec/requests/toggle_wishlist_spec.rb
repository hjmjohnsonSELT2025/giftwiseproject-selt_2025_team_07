require "rails_helper"

RSpec.describe "Toggle Wishlist", type: :request do
  let(:owner) { create(:user) }
  let(:co_planner) { create(:user) }
  let(:viewer) { create(:user) }

  let!(:event) { create(:event, user: owner) }
  let!(:recipient) { create(:recipient, user: owner) }
  let!(:event_recipient) { create(:event_recipient, user: owner, event: event, recipient: recipient) }
  let!(:suggestion) { create(:ai_gift_suggestion, user: owner, event: event, recipient: recipient, event_recipient: event_recipient) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(owner)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)

    create(:collaborator, event: event, user: co_planner,
           status: Collaborator::STATUS_ACCEPTED,
           role: Collaborator::ROLE_CO_PLANNER)

    create(:collaborator, event: event, user: viewer,
           status: Collaborator::STATUS_ACCEPTED,
           role: Collaborator::ROLE_VIEWER)
  end

  it "saves wishlist for owner + accepted co_planners/owners (not viewers)" do
    expect {
      post toggle_wishlist_event_ai_gift_suggestion_path(event, suggestion), params: { from: "ai_library" }
    }.to change { Wishlist.where(ai_gift_suggestion_id: suggestion.id).count }.from(0).to(2)

    ids = Wishlist.where(ai_gift_suggestion_id: suggestion.id).pluck(:user_id)
    expect(ids).to match_array([owner.id, co_planner.id])
  end

  it "removes wishlist for all planner_ids when toggled off" do
    Wishlist.create!(user_id: owner.id, ai_gift_suggestion_id: suggestion.id, recipient_id: recipient.id)
    Wishlist.create!(user_id: co_planner.id, ai_gift_suggestion_id: suggestion.id, recipient_id: recipient.id)

    expect {
      post toggle_wishlist_event_ai_gift_suggestion_path(event, suggestion), params: { from: "ai_library" }
    }.to change { Wishlist.where(ai_gift_suggestion_id: suggestion.id).count }.from(2).to(0)
  end
end
