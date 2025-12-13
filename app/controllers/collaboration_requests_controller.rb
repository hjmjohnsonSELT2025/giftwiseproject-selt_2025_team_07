# app/controllers/collaboration_requests_controller.rb
class CollaborationRequestsController < ApplicationController
  before_action :authenticate_user!

  def index
    @pending_collaborations = Collaborator
                                .where(user_id: current_user.id, status: Collaborator::STATUS_PENDING)
                                .includes(:event, :event => :user)

    @all_collaborations = Collaborator
                            .where(user_id: current_user.id)
                            .includes(:event, :event => :user)
                            .order("created_at DESC")
  end

  def accept
    collaboration = current_user.collaborators.pending.find_by(id: params[:id])

    unless collaboration
      redirect_to collaboration_requests_path,
                  alert: "Collaboration request not found."
      return
    end

    if collaboration.update(status: Collaborator::STATUS_ACCEPTED)
      redirect_to collaboration_requests_path,
                  notice: "Collaboration request accepted!"
    else
      Rails.logger.error(
        "Collaboration accept failed for id=#{collaboration.id}: " \
          "#{collaboration.errors.full_messages.join(', ')}"
      )
      redirect_to collaboration_requests_path,
                  alert: "Could not accept collaboration request."
    end
  end

  def reject
    collaboration = current_user.collaborators.pending.find_by(id: params[:id])

    unless collaboration
      redirect_to collaboration_requests_path,
                  alert: "Collaboration request not found."
      return
    end

    if collaboration.update(status: Collaborator::STATUS_DECLINED)
      redirect_to collaboration_requests_path,
                  notice: "Collaboration request declined."
    else
      Rails.logger.error(
        "Collaboration reject failed for id=#{collaboration.id}: " \
          "#{collaboration.errors.full_messages.join(', ')}"
      )
      redirect_to collaboration_requests_path,
                  alert: "Could not reject collaboration request."
    end
  end
end
