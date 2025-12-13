# spec/models/collaborator_spec.rb
require "rails_helper"

RSpec.describe Collaborator, type: :model do
  let(:owner)   { create(:user) }
  let(:user)    { create(:user) }
  let(:event)   { create(:event, user: owner) }

  it "is valid with a known role and status" do
    collab = described_class.new(
      event: event,
      user: user,
      role: Collaborator::ROLE_VIEWER,
      status: Collaborator::STATUS_PENDING
    )
    expect(collab).to be_valid
  end

  it "is invalid with an unknown role" do
    collab = described_class.new(
      event: event,
      user: user,
      role: "bad_role",
      status: Collaborator::STATUS_PENDING
    )
    expect(collab).not_to be_valid
    expect(collab.errors[:role]).to be_present
  end

  it "is invalid with an unknown status" do
    collab = described_class.new(
      event: event,
      user: user,
      role: Collaborator::ROLE_VIEWER,
      status: "bad_status"
    )
    expect(collab).not_to be_valid
    expect(collab.errors[:status]).to be_present
  end

  it "scopes pending and accepted" do
    pending  = create(:collaborator, event: event, user: user, status: Collaborator::STATUS_PENDING)
    accepted = create(:collaborator, event: event, user: create(:user), status: Collaborator::STATUS_ACCEPTED)

    expect(described_class.pending).to include(pending)
    expect(described_class.pending).not_to include(accepted)

    expect(described_class.accepted).to include(accepted)
    expect(described_class.accepted).not_to include(pending)
  end

  it "role/status helper methods work" do
    collab = create(:collaborator,
                    event: event,
                    user: user,
                    role: Collaborator::ROLE_CO_PLANNER,
                    status: Collaborator::STATUS_ACCEPTED
    )

    expect(collab.co_planner?).to eq(true)
    expect(collab.owner?).to eq(false)
    expect(collab.viewer?).to eq(false)

    expect(collab.accepted?).to eq(true)
    expect(collab.pending?).to eq(false)
    expect(collab.declined?).to eq(false)
  end

  it "role_label returns a human label" do
    expect(build(:collaborator, role: Collaborator::ROLE_OWNER).role_label).to eq("Owner")
    expect(build(:collaborator, role: Collaborator::ROLE_CO_PLANNER).role_label).to eq("Co-Planner")
    expect(build(:collaborator, role: Collaborator::ROLE_VIEWER).role_label).to eq("Viewer")
  end
end
