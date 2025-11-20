# app/controllers/gift_ideas_controller.rb
class GiftIdeasController < ApplicationController
  before_action :set_recipient
  before_action :set_event_recipient

  def new
    @gift_idea = @event_recipient.gift_ideas.new
  end

  def create
    @gift_idea = @event_recipient.gift_ideas.new(gift_idea_params)

    if @gift_idea.save
      # If your Cucumber step says:
      # Then I should be on the recipient page
      # use recipient_path(@recipient).
      redirect_to recipient_path(@recipient),
                  notice: "Gift idea added successfully."
    else
      flash.now[:alert] = "Please fix the errors below."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @gift_idea = GiftIdea.find(params[:id])
    @gift_idea.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("gift_idea_#{params[:id]}") }
      format.html { redirect_to recipients_path, notice: "Gift idea removed successfully." }
    end
  end

  private

  def set_recipient
    # If you have current_user, it’s safer to scope:
    # @recipient = current_user.recipients.find(params[:recipient_id])
    @recipient = Recipient.find(params[:recipient_id])
  end

  def set_event_recipient
    @event_recipient = EventRecipient.find_by!(recipient_id: @recipient.id)
  end

  def gift_idea_params
    params.require(:gift_idea)
          .permit(:idea, :description, :price_estimate, :link)
          .merge(event_recipient_id: @event_recipient.id)
  end
end
