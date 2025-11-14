class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: [:show, :edit, :update, :destroy]

  def index
    @upcoming_events = current_user.events.upcoming
    @past_events = current_user.events.past
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
  end

  def edit
    @recipients = current_user.recipients
  end

  def update
    if @event.update(event_params)
      redirect_to event_path(@event), notice: "Event updated successfully!"
    else
      @recipients = current_user.recipients
      render :edit, status: :unprocessable_entity
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