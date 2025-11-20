class GiftGivenBacklogsController < ApplicationController
  before_action :set_recipient

  def new
    @recipient = Recipient.find(params[:recipient_id])
    @gift_given_backlog = @recipient.gift_given_backlogs.new
  end


  def create
    @recipient = Recipient.find(params[:recipient_id])
    @gift_given_backlog = @recipient.gift_given_backlogs.new(gift_given_backlog_params)
    @gift_given_backlog.user_id = current_user.id  # ⭐ ADD THIS

    if @gift_given_backlog.save
      redirect_to recipients_path, notice: "Gift given record added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end


  def destroy
    @gift_given = @recipient.gift_given_backlogs.find(params[:id])
    @gift_given.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("gift_given_#{params[:id]}") }
      format.html { redirect_to @recipient }
    end
  end



  private

  def set_recipient
    @recipient = Recipient.find(params[:recipient_id])
  end

  private

  def gift_given_backlog_params
    params.require(:gift_given_backlog).permit(
      :gift_name,
      :description,
      :price,
      :category,
      :purchase_link,
      :given_on,
      :event_id,
      :event_name,
      :created_from_idea_id
    )
  end

end
