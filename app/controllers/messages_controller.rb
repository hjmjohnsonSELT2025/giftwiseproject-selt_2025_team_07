# frozen_string_literal: true

# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_friend, only: [:index, :create, :clear]

  # Display chat with a friend
  def index
    # Get messages between users that current user hasn't deleted
    @messages = Message.between(current_user, @friend)
                       .visible_to(current_user)

    # Mark messages from friend as read
    Message.where(sender: @friend, receiver: current_user, read: false)
           .visible_to(current_user)
           .each(&:mark_as_read!)

    @message = Message.new
  end

  # Send a new message
  def create
    @message = current_user.sent_messages.build(message_params)
    @message.receiver = @friend

    if @message.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to messages_path(friend_id: @friend.id) }
      end
    else
      @messages = Message.between(current_user, @friend).visible_to(current_user)
      render :index, status: :unprocessable_entity
    end
  end

  # List conversations with friends who have messages
  def conversations
    @friends_with_messages = current_user.friends.select do |friend|
      Message.between(current_user, friend).visible_to(current_user).any?
    end
  end

  # Clear chat - only marks messages as deleted for current user (soft delete)
  # The other user will still see all messages
  def clear
    # Get all messages between current user and friend
    messages = Message.where(
      "(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
      current_user.id, @friend.id, @friend.id, current_user.id
    )

    # Mark each message as deleted for current user (soft delete)
    messages.each do |message|
      message.mark_deleted_for(current_user)
    end

    respond_to do |format|
      format.html {
        redirect_to messages_path(friend_id: @friend.id),
                    notice: "Chat with #{@friend.name} has been cleared from your view."
      }
      format.turbo_stream
    end
  end

  private

  # Set the friend for the conversation
  def set_friend
    @friend = User.find(params[:friend_id])
    unless current_user.friend?(@friend)
      redirect_to friendships_path, alert: 'You can only message friends.'
    end
  end

  # Strong parameters for message
  def message_params
    params.require(:message).permit(:body)
  end
end