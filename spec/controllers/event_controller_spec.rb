# spec/controllers/events_controller_spec.rb
require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password123") }
  let(:other_user) { User.create!(name: "Other User", email: "other@example.com", password: "password123") }

  let(:event) do
    Event.create!(
      user: user,
      event_name: "Birthday Party",
      event_date: Date.tomorrow,
      description: "Test event"
    )
  end

  let(:recipient1) do
    Recipient.create!(
      user: user,
      name: "John Doe",
      age: 30,
      relationship: "Friend"
    )
  end

  let(:recipient2) do
    Recipient.create!(
      user: user,
      name: "Jane Smith",
      age: 25,
      relationship: "Family"
    )
  end

  let(:other_user_recipient) do
    Recipient.create!(
      user: other_user,
      name: "Bob Jones",
      age: 35,
      relationship: "Colleague"
    )
  end

  before do
    # Simulate user login by setting session
    session[:user_id] = user.id
  end

  describe "GET #show" do

    context "with some recipients already added" do
      before do
        EventRecipient.create!(event: event, recipient: recipient1, user: user)
      end

    end

    context "with all recipients added" do
      before do
        EventRecipient.create!(event: event, recipient: recipient1, user: user)
        EventRecipient.create!(event: event, recipient: recipient2, user: user)
      end

    end
  end

  describe "POST #add_recipient" do
    context "with valid recipient" do
      it "creates a new event_recipient record" do
        expect {
          post :add_recipient, params: { id: event.id, recipient_id: recipient1.id }
        }.to change(EventRecipient, :count).by(1)
      end

      it "associates the recipient with the event" do
        post :add_recipient, params: { id: event.id, recipient_id: recipient1.id }

        expect(event.reload.recipients).to include(recipient1)
      end

      it "sets the correct user_id on event_recipient" do
        post :add_recipient, params: { id: event.id, recipient_id: recipient1.id }

        event_recipient = EventRecipient.last
        expect(event_recipient.user_id).to eq(user.id)
      end

      it "redirects to event show page with success notice" do
        post :add_recipient, params: { id: event.id, recipient_id: recipient1.id }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to eq("#{recipient1.name} added to event successfully!")
      end
    end

    context "with recipient already added to event" do
      before do
        EventRecipient.create!(event: event, recipient: recipient1, user: user)
      end

      it "does not create a duplicate record" do
        expect {
          post :add_recipient, params: { id: event.id, recipient_id: recipient1.id }
        }.not_to change(EventRecipient, :count)
      end

      it "redirects with alert message" do
        post :add_recipient, params: { id: event.id, recipient_id: recipient1.id }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to eq("#{recipient1.name} is already added to this event")
      end
    end

    context "with non-existent recipient" do
      it "does not create a record" do
        expect {
          post :add_recipient, params: { id: event.id, recipient_id: 99999 }
        }.not_to change(EventRecipient, :count)
      end

      it "redirects with error message" do
        post :add_recipient, params: { id: event.id, recipient_id: 99999 }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to eq("Recipient not found")
      end
    end




    context "when user is not logged in" do
      before do
        session[:user_id] = nil
      end

      it "redirects to login page" do
        post :add_recipient, params: { id: event.id, recipient_id: recipient1.id }

        expect(response).to redirect_to(login_path)
      end
    end

    context "with another user's event" do
      let(:other_event) do
        Event.create!(
          user: other_user,
          event_name: "Other Event",
          event_date: Date.tomorrow
        )
      end

      it "raises RecordNotFound error" do
        expect {
          post :add_recipient, params: { id: other_event.id, recipient_id: recipient1.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "DELETE #remove_recipient" do
    let!(:event_recipient) do
      EventRecipient.create!(event: event, recipient: recipient1, user: user)
    end

    context "with valid event_recipient" do
      it "deletes the event_recipient record" do
        expect {
          delete :remove_recipient, params: { id: event.id, event_recipient_id: event_recipient.id }
        }.to change(EventRecipient, :count).by(-1)
      end

      it "removes the recipient from the event" do
        delete :remove_recipient, params: { id: event.id, event_recipient_id: event_recipient.id }

        expect(event.reload.recipients).not_to include(recipient1)
      end

      it "redirects to event show page with success notice" do
        delete :remove_recipient, params: { id: event.id, event_recipient_id: event_recipient.id }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to eq("#{recipient1.name} removed from event")
      end
    end

    context "with non-existent event_recipient" do
      it "does not delete any record" do
        expect {
          delete :remove_recipient, params: { id: event.id, event_recipient_id: 99999 }
        }.not_to change(EventRecipient, :count)
      end

      it "redirects with error message" do
        delete :remove_recipient, params: { id: event.id, event_recipient_id: 99999 }

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to eq("Recipient not found in this event")
      end
    end

    context "when user is not logged in" do
      before do
        session[:user_id] = nil
      end

      it "redirects to login page" do
        delete :remove_recipient, params: { id: event.id, event_recipient_id: event_recipient.id }

        expect(response).to redirect_to(login_path)
      end
    end
  end
  end

