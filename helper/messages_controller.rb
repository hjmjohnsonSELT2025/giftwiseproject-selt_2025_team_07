class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_friend, only: [:index, :create]

  def index
    @messages = Message.between(current_user, @friend)
    
    # Mark messages from friend as read
    Message.where(sender: @friend, receiver: current_user, read: false)
           .update_all(read: true)
    
    @message = Message.new
  end

  def create
    @message = current_user.sent_messages.build(message_params)
    @message.receiver = @friend

    if @message.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to messages_path(friend_id: @friend.id) }
      end
    else
      render :index, status: :unprocessable_entity
    end
  end

  def conversations
    @friends_with_messages = current_user.friends.select do |friend|
      Message.between(current_user, friend).exists?
    end
  end

  private

  def set_friend
    @friend = User.find(params[:friend_id])
    unless current_user.friend?(@friend)
      redirect_to friendships_path, alert: 'You can only message friends.'
    end
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
