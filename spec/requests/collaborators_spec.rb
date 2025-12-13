require "rails_helper"

RSpec.describe "Collaborators", type: :request do
  let(:owner)   { create(:user, email: "owner@example.com", name: "Owner") }
  let!(:invitee) { create(:user, email: "invitee@example.com", name: "Invitee") } # <-- IMPORTANT
  let(:event)   { create(:event, user: owner) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
  end

  def stub_current_user(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "POST /events/:event_id/collaborators" do
    it "allows the event owner to invite by user_id and creates a pending collaborator" do
      stub_current_user(owner)

      expect {
        post event_collaborators_path(event_id: event.id), params: {
          collaborator: { user_id: invitee.id, role: Collaborator::ROLE_CO_PLANNER }
        }
      }.to change(Collaborator, :count).by(1)

      collab = Collaborator.last
      expect(collab.event_id).to eq(event.id)
      expect(collab.user_id).to eq(invitee.id)
      expect(collab.role).to eq(Collaborator::ROLE_CO_PLANNER)
      expect(collab.status).to eq(Collaborator::STATUS_PENDING)
      expect(response).to redirect_to(event_path(event))
    end

    it "allows the event owner to invite by email (case-insensitive) when user exists" do
      stub_current_user(owner)

      expect {
        post event_collaborators_path(event_id: event.id), params: {
          email: "INVITEE@EXAMPLE.COM",
          role: Collaborator::ROLE_VIEWER
        }
      }.to change(Collaborator, :count).by(1)

      collab = Collaborator.last
      expect(collab.user_id).to eq(invitee.id)
      expect(collab.role).to eq(Collaborator::ROLE_VIEWER)
      expect(collab.status).to eq(Collaborator::STATUS_PENDING)
      expect(response).to redirect_to(event_path(event))
    end

    it "creates an email invite when email does not belong to a user" do
      stub_current_user(owner)

      expect {
        post event_collaborators_path(event_id: event.id), params: {
          email: "newperson@example.com",
          role: Collaborator::ROLE_VIEWER
        }
      }.to change(CollaborationInvite, :count).by(1)

      invite = CollaborationInvite.last
      expect(invite.event_id).to eq(event.id)
      expect(invite.inviter_id).to eq(owner.id)
      expect(invite.invitee_email).to eq("newperson@example.com")
      expect(invite.role).to eq(Collaborator::ROLE_VIEWER)
      expect(invite.status).to eq("pending")
      expect(invite.token).to be_present
      expect(response).to redirect_to(event_path(event))
    end

    it "rejects invite when current_user is not the event owner" do
      stub_current_user(invitee)

      expect {
        post event_collaborators_path(event_id: event.id), params: {
          collaborator: { user_id: owner.id, role: Collaborator::ROLE_VIEWER }
        }
      }.not_to change(Collaborator, :count)

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(response.body).to include("Only the event owner can invite collaborators.")
    end
  end
end
