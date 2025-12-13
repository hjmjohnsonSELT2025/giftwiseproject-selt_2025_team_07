# frozen_string_literal: true

class FriendshipsController < ApplicationController
  before_action :authenticate_user!

  # GET /friendships
  def index
    # Incoming friend requests (people who sent requests TO me)
    @pending_requests = current_user.pending_friend_requests

    # Outgoing friend requests (people I sent requests TO) - for search dropdown
    @sent_friend_requests = current_user.sent_friend_requests

    @friends          = current_user.friends

    # All NON friend users (to show in search dropdown)
    @potential_friends =
      User.where.not(id: current_user.id)
          .where.not(id: current_user.friends.select(:id))                    # already friends
          .where.not(id: current_user.sent_friend_requests.select(:friend_id)) # I sent pending
          .where.not(id: current_user.pending_friend_requests.select(:user_id)) # they sent pending
          .order(:name) # Sort alphabetically for better UX
  end

  # POST /friendships
  # app/controllers/friendships_controller.rb
  def create
    @friend = User.find(params[:friend_id])
    @friendship = current_user.friendships.build(friend: @friend, status: 'pending')

    if @friendship.save
      respond_to do |format|
        format.turbo_stream   # will render create.turbo_stream.erb
        format.html do
          flash[:success] = "Friend request sent to #{@friend.name}"
          redirect_to friendships_path
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend(
            "flash-messages",
            partial: "shared/flash",
            locals: { type: "error", message: "Failed to send friend request" }
          )
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

    if @friendship.update(status: "accepted")
      # Create reverse friendship (bidirectional friendship)
      Friendship.find_or_create_by(
        user_id: current_user.id,
        friend_id: @friendship.user_id,
        status: "accepted"
      )

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("pending_request_#{@friendship.id}"),
            turbo_stream.update(
              "pending_count",
              partial: "friendships/pending_count",
              locals: { count: current_user.pending_friend_requests.count }
            ),
            turbo_stream.prepend(
              "friends_list",
              partial: "friendships/friend_card",
              locals: { friend: @friendship.user }
            ),
            turbo_stream.update(
              "friends_count",
              "#{current_user.friends.count} friends"
            ),
            turbo_stream.prepend(
              "flash-messages",
              partial: "shared/flash",
              locals: {
                type: "success",
                message: "You are now friends with #{@friendship.user.name}!"
              }
            )
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
          render turbo_stream: turbo_stream.prepend(
            "flash-messages",
            partial: "shared/flash",
            locals: {
              type: "error",
              message: "Failed to accept friend request"
            }
          )
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
            turbo_stream.update(
              "pending_count",
              partial: "friendships/pending_count",
              locals: { count: current_user.pending_friend_requests.count }
            ),
            turbo_stream.prepend(
              "flash-messages",
              partial: "shared/flash",
              locals: {
                type: "success",
                message: "Friend request rejected"
              }
            )
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
          render turbo_stream: turbo_stream.prepend(
            "flash-messages",
            partial: "shared/flash",
            locals: {
              type: "error",
              message: "Failed to reject friend request"
            }
          )
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
    @friend      = @friendship.friend
    friend_name  = @friend.name

    # Find and destroy the reverse friendship as well
    reverse_friendship = Friendship.find_by(
      user_id: @friend.id,
      friend_id: current_user.id
    )

    ActiveRecord::Base.transaction do
      @friendship.destroy!
      reverse_friendship&.destroy!
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("friend_card_#{@friend.id}"),
          turbo_stream.update(
            "friends_count",
            "#{current_user.friends.count} friends"
          ),
          turbo_stream.prepend(
            "flash-messages",
            partial: "shared/flash",
            locals: {
              type: "success",
              message: "Removed #{friend_name} from your friends"
            }
          )
        ]
      end
      format.html do
        flash[:success] = "Removed #{friend_name} from your friends"
        redirect_to friendships_path
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.prepend(
          "flash-messages",
          partial: "shared/flash",
          locals: {
            type: "error",
            message: "Friendship not found"
          }
        )
      end
      format.html do
        flash[:error] = "Friendship not found"
        redirect_to friendships_path
      end
    end
  end
end