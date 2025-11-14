class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: [:show, :edit, :update, :destroy, :add_recipient, :remove_recipient]

  def index
    @upcoming_events = current_user.events.upcoming
    @past_events = current_user.events.past

    @event = current_user.events.build
  end

  def new
    @event = Event.new
    @recipients = current_user.recipients
  end

  def create
    @event = current_user.events.build(event_params)

    if @event.save
      # Add recipients to event if selected
      if params[:recipient_ids].present?
        params[:recipient_ids].reject(&:blank?).each do |recipient_id|
          @event.event_recipients.create(
            recipient_id: recipient_id,
            user_id: current_user.id
          )
        end
      end

      redirect_to dashboard_path, notice: "Event '#{@event.event_name}' created successfully!"
    else
      @recipients = current_user.recipients
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @event_recipients = @event.event_recipients.includes(:recipient)

    # Get all recipients belonging to the current user
    @all_recipients = current_user.recipients.order(:name)

    # Get IDs of recipients already added to this event
    @added_recipient_ids = @event_recipients.pluck(:recipient_id)

    # Get available recipients (not yet added to this event)
    @available_recipients = @all_recipients.where.not(id: @added_recipient_ids)
  end

  def edit
    @recipients = current_user.recipients
  end

  def update
    if @event.update(event_params)
      # Update recipients if some were submitted
      if params[:recipient_ids]
        @event.event_recipients.destroy_all

        params[:recipient_ids].reject(&:blank?).each do |recipient_id|
          @event.event_recipients.create(
            recipient_id: recipient_id,
            user_id: current_user.id
          )
        end
      end

      redirect_to event_path(@event), notice: "Event updated successfully!"
    else
      @recipients = current_user.recipients
      render :edit, status: :unprocessable_entity
    end
  end

  # NEW ACTION: Add a recipient to the event
  def add_recipient
    recipient = current_user.recipients.find_by(id: params[:recipient_id])

    if recipient.nil?
      redirect_to event_path(@event), alert: "Recipient not found"
      return
    end

    # Check if recipient is already added to this event
    existing = @event.event_recipients.find_by(recipient_id: recipient.id)

    if existing
      redirect_to event_path(@event), alert: "#{recipient.name} is already added to this event"
    else
      event_recipient = @event.event_recipients.create(
        recipient_id: recipient.id,
        user_id: current_user.id
      )

      if event_recipient.persisted?
        redirect_to event_path(@event), notice: "#{recipient.name} added to event successfully!"
      else
        redirect_to event_path(@event), alert: "Failed to add recipient to event"
      end
    end
  end

  # NEW ACTION: Remove a recipient from the event
  def remove_recipient
    event_recipient = @event.event_recipients.find_by(id: params[:event_recipient_id])

    if event_recipient
      recipient_name = event_recipient.recipient.name
      event_recipient.destroy
      redirect_to event_path(@event), notice: "#{recipient_name} removed from event"
    else
      redirect_to event_path(@event), alert: "Recipient not found in this event"
    end
  end

  def destroy
    event_name = @event.event_name
    @event.destroy
    redirect_to events_path, notice: "Event '#{event_name}' deleted successfully!"
  end

  private

  def set_event
    @event = current_user.events.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:event_name, :description, :event_date, :location, :budget)
  end
end