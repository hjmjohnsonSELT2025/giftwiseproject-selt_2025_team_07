# app/controllers/recipients_controller.rb
class RecipientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipient, only: [:show, :edit, :update, :destroy]

  def index
    @recipients = current_user.recipients
  end

  def new
    @recipient = current_user.recipients.new
  end

  def show
  end

  def edit
  end

  def create
    @recipient = current_user.recipients.new(recipient_params)

    if @recipient.save
      redirect_to dashboard_path
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @recipient.update(recipient_params)
      redirect_to recipients_path
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @recipient.destroy
    redirect_to recipients_path
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
