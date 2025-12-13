class FriendshipsController < ApplicationController
  before_action :authenticate_user!

  def index
    @friends = current_user.friends.order(:name)
    @pending_requests = current_user.pending_friend_requests.includes(:user)
    @other_users = User.where.not(id: current_user.id)
                       .where.not(id: current_user.friends.pluck(:id))
                       .where.not(id: current_user.sent_friend_requests.pluck(:friend_id))
                       .where.not(id: current_user.pending_friend_requests.pluck(:user_id))
                       .order(:name)
  end

  def create
    friend = User.find(params[:friend_id])
    
    @friendship = current_user.friendships.build(friend: friend, status: 'pending')
    
    if @friendship.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to friendships_path, notice: 'Friend request sent!' }
      end
    else
      redirect_to friendships_path, alert: 'Could not send friend request.'
    end
  end

  def update
    @friendship = Friendship.find(params[:id])
    
    if @friendship.friend_id == current_user.id
      case params[:status]
      when 'accept'
        @friendship.accept!
        flash[:notice] = 'Friend request accepted!'
      when 'reject'
        @friendship.reject!
        flash[:notice] = 'Friend request rejected.'
      end
    end

    redirect_to friendships_path
  end

  def destroy
    friendship = current_user.friendships.find(params[:id])
    reciprocal = Friendship.find_by(user: friendship.friend, friend: current_user)
    
    friendship.destroy
    reciprocal&.destroy
    
    redirect_to friendships_path, notice: 'Friend removed.'
  end
end
