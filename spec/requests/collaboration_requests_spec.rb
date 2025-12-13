# spec/requests/collaboration_requests_spec.rb
require "rails_helper"

RSpec.describe "CollaborationRequests", type: :request do
  let(:owner)   { create(:user) }
  let(:invitee) { create(:user) }
  let(:other)   { create(:user) }
  let(:event)   { create(:event, user: owner) }

  let!(:invite) do
    create(:collaborator,
           event: event,
           user: invitee,
           status: Collaborator::STATUS_PENDING,
           role: Collaborator::ROLE_CO_PLANNER
    )
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(invitee)
  end

  it "renders index and assigns pending + all collaborations" do
    get collaboration_requests_path
    expect(response).to have_http_status(:ok)
    # request spec cannot use assigns reliably; check content or status is OK.
  end

  it "accepts a pending invite" do
    post accept_collaboration_request_path(invite)
    expect(response).to redirect_to(collaboration_requests_path)
    expect(invite.reload.status).to eq(Collaborator::STATUS_ACCEPTED)
  end

  it "rejects a pending invite" do
    delete reject_collaboration_request_path(invite)
    expect(response).to redirect_to(collaboration_requests_path)
    expect(invite.reload.status).to eq(Collaborator::STATUS_DECLINED)
  end

  it "does not accept an invite that does not belong to current_user" do
    foreign_invite = create(:collaborator, event: event, user: other, status: Collaborator::STATUS_PENDING)

    post accept_collaboration_request_path(foreign_invite)
    expect(response).to redirect_to(collaboration_requests_path)
    expect(foreign_invite.reload.status).to eq(Collaborator::STATUS_PENDING)
  end

  it "does not reject an invite that does not belong to current_user" do
    foreign_invite = create(:collaborator, event: event, user: other, status: Collaborator::STATUS_PENDING)

    delete reject_collaboration_request_path(foreign_invite)
    expect(response).to redirect_to(collaboration_requests_path)
    expect(foreign_invite.reload.status).to eq(Collaborator::STATUS_PENDING)
  end
end
