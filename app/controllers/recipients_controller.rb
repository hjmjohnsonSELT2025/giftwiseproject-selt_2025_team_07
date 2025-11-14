class RecipientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipient, only: [:show, :edit, :update, :destroy]


  def index
    @query = params[:query].to_s.strip
    @recipients = current_user.recipients.order(:name)

    if @query.present?
      q = "%#{@query.downcase}%"
      @recipients = @recipients.where(
        "LOWER(name) LIKE ? OR LOWER(email) LIKE ? OR LOWER(relationship) LIKE ?",
        q, q, q
      )
    end
  end

  def show
    # @recipient is already set by set_recipient
  end


  def new
    @recipient = current_user.recipients.build
  end

  def create
    @recipient = current_user.recipients.build(recipient_params)

    if @recipient.save
      redirect_to dashboard_path,
                  notice: "Recipient '#{@recipient.name}' added successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @recipient.update(recipient_params)
      redirect_to recipients_path,
                  notice: "Recipient '#{@recipient.name}' updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @recipient.name
    @recipient.destroy
    redirect_to recipients_path,
                notice: "Recipient '#{name}' removed successfully!"
  end

  private

  def set_recipient
    @recipient = current_user.recipients.find(params[:id])
  end

  def recipient_params
    params.require(:recipient).permit(
      :name,
      :email,
      :relationship,
      :age,
      :gender,
      :occupation,
      :bio,
      :hobbies,
      :likes,
      :favorite_categories,
      :dislikes,
      :budget
    )
  end
end
