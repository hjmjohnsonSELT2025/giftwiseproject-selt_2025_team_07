require "rails_helper"

RSpec.describe GiftGivenBacklogsController, type: :request do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "Password@123"
    )
  end

  let(:recipient) do
    Recipient.create!(
      name: "Sam",
      relationship: "Friend",
      user: user
    )
  end

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:current_user)
            .and_return(user)
  end


  describe "GET /recipients/:recipient_id/gift_given_backlogs/new" do
    it "renders the new template successfully" do
      get new_recipient_gift_given_backlog_path(recipient)

      expect(response).to have_http_status(:ok)
      # Optional: check some text from the form if you want
      # expect(response.body).to include("Gift name")
    end
  end

  describe "POST /recipients/:recipient_id/gift_given_backlogs" do
    let(:valid_params) do
      {
        gift_given_backlog: {
          gift_name: "Watch",
          description: "Nice gift",
          price: 100,
          category: "Birthday",
          purchase_link: "https://example.com/watch",
          given_on: Date.today,
          event_id: nil,
          event_name: "Birthday",
          created_from_idea_id: nil
        }
      }
    end

    it "creates a gift_given_backlog and redirects on success" do
      expect {
        post recipient_gift_given_backlogs_path(recipient), params: valid_params
      }.to change { GiftGivenBacklog.count }.by(1)

      gift = GiftGivenBacklog.last
      expect(gift.user_id).to eq(user.id)
      expect(gift.recipient_id).to eq(recipient.id)

      expect(response).to redirect_to(recipients_path)
      follow_redirect!
      expect(response.body).to include("Gift given record added successfully").or include("Gift given record")
    end

    it "re-renders new with unprocessable_entity when save fails" do
      # Force save to fail regardless of validations
      allow_any_instance_of(GiftGivenBacklog).to receive(:save).and_return(false)

      post recipient_gift_given_backlogs_path(recipient), params: valid_params

      expect(response).to have_http_status(:unprocessable_entity)
      # Optional: check the form is shown again
      # expect(response.body).to include("Gift name")
    end
  end

  describe "DELETE /recipients/:recipient_id/gift_given_backlogs/:id" do
    let!(:gift_given) do
      GiftGivenBacklog.create!(
        gift_name: "Book",
        description: "Good read",
        price: 20,
        category: "Birthday",
        purchase_link: "https://example.com/book",
        given_on: Date.today,
        event_id: nil,
        event_name: "Birthday",
        created_from_idea_id: nil,
        recipient: recipient,
        user: user
      )
    end

    it "destroys the record and returns turbo_stream when requested" do
      expect {
        delete recipient_gift_given_backlog_path(recipient, gift_given),
               headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
      }.to change { GiftGivenBacklog.count }.by(-1)

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("turbo-stream").or include("turbo_stream")
      # It should have removed element gift_given_<id>
      expect(response.body).to include("gift_given_#{gift_given.id}")
    end

    it "destroys the record and redirects for HTML requests" do
      new_gift = GiftGivenBacklog.create!(
        gift_name: "Pen",
        description: "Blue pen",
        price: 5,
        category: "Office",
        purchase_link: "https://example.com/pen",
        given_on: Date.today,
        event_id: nil,
        event_name: "Office",
        created_from_idea_id: nil,
        recipient: recipient,
        user: user
      )

      expect {
        delete recipient_gift_given_backlog_path(recipient, new_gift)
      }.to change { GiftGivenBacklog.count }.by(-1)

      expect(response).to redirect_to(recipient_path(recipient))
    end
  end
end
