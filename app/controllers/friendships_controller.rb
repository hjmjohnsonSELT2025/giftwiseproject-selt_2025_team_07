# frozen_string_literal: true

# app/controllers/friendships_controller.rb
class FriendshipsController < ApplicationController
  before_action :require_login

  def index
    @pending_requests = current_user.pending_friend_requests
    @friends = current_user.friends
    @potential_friends = User.where.not(id: current_user.id)
                             .where.not(id: current_user.friends.pluck(:id))
                             .where.not(id: current_user.sent_friend_requests.pluck(:friend_id))
                             .where.not(id: current_user.pending_friend_requests.pluck(:id))
  end

  def create
    @friend = User.find(params[:friend_id])

    # Create friendship request
    friendship = current_user.friendships.build(friend: @friend, status: 'pending')

    if friendship.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("potential_friend_#{@friend.id}"),
            turbo_stream.prepend("flash-messages", partial: "shared/flash",
                                 locals: { type: "success", message: "Friend request sent to #{@friend.name}" })
          ]
        end
        format.html do
          flash[:success] = "Friend request sent to #{@friend.name}"
          redirect_to friendships_path
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash-messages",
                                                    partial: "shared/flash",
                                                    locals: { type: "error", message: "Failed to send friend request" })
        end
        format.html do
          flash[:error] = "Failed to send friend request"
          redirect_to friendships_path
        end
      end
    end
  end

  def accept
    @friendship = current_user.received_friendships.find(params[:id])

    if @friendship.update(status: 'accepted')
      # Create reverse friendship so both users are friends with each other
      Friendship.find_or_create_by(
        user_id: current_user.id,
        friend_id: @friendship.user_id,
        status: 'accepted'
      )

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("pending_request_#{@friendship.id}"),
            turbo_stream.update("pending_count",
                                partial: "friendships/pending_count",
                                locals: { count: current_user.pending_friend_requests.count }),
            turbo_stream.prepend("friends_list",
                                 partial: "friendships/friend_card",
                                 locals: { friend: @friendship.user }),
            turbo_stream.update("friends_count", "#{current_user.friends.count} friends"),
            turbo_stream.prepend("flash-messages",
                                 partial: "shared/flash",
                                 locals: { type: "success", message: "You are now friends with #{@friendship.user.name}!" })
          ]
        end
        format.html do
          flash[:success] = "You are now friends with #{@friendship.user.name}!"
          redirect_to friendships_path
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash-messages",
                                                    partial: "shared/flash",
                                                    locals: { type: "error", message: "Failed to accept friend request" })
        end
        format.html do
          flash[:error] = "Failed to accept friend request"
          redirect_to friendships_path
        end
      end
    end
  end

  def reject
    @friendship = current_user.received_friendships.find(params[:id])

    if @friendship.destroy
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("pending_request_#{@friendship.id}"),
            turbo_stream.update("pending_count",
                                partial: "friendships/pending_count",
                                locals: { count: current_user.pending_friend_requests.count }),
            turbo_stream.prepend("flash-messages",
                                 partial: "shared/flash",
                                 locals: { type: "success", message: "Friend request rejected" })
          ]
        end
        format.html do
          flash[:success] = "Friend request rejected"
          redirect_to friendships_path
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash-messages",
                                                    partial: "shared/flash",
                                                    locals: { type: "error", message: "Failed to reject friend request" })
        end
        format.html do
          flash[:error] = "Failed to reject friend request"
          redirect_to friendships_path
        end
      end
    end
  end

  def destroy
    @friendship = current_user.friendships.find(params[:id])
    friend_name = @friendship.friend.name

    # Delete both sides of the friendship
    reverse_friendship = Friendship.find_by(user_id: @friendship.friend_id, friend_id: current_user.id)
    reverse_friendship&.destroy

    if @friendship.destroy
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("friend_#{@friendship.friend_id}"),
            turbo_stream.update("friends_count", "#{current_user.friends.count} friends"),
            turbo_stream.prepend("flash-messages",
                                 partial: "shared/flash",
                                 locals: { type: "success", message: "Removed #{friend_name} from friends" })
          ]
        end
        format.html do
          flash[:success] = "Removed #{friend_name} from friends"
          redirect_to friendships_path
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash-messages",
                                                    partial: "shared/flash",
                                                    locals: { type: "error", message: "Failed to remove friend" })
        end
        format.html do
          flash[:error] = "Failed to remove friend"
          redirect_to friendships_path
        end
      end
    end
  end

  private

  def require_login
    unless current_user
      flash[:error] = "You must be logged in to access this page"
      redirect_to login_path
    end
  end
end