# frozen_string_literal: true

class CollaboratorsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event

  # POST /events/:event_id/collaborators
  # Supports inviting by friend_id OR email
  def create
    unless @event.owner?(current_user)
      redirect_to dashboard_path, alert: "Only the event owner can invite collaborators."
      return
    end

    role    = (params.dig(:collaborator, :role) || params[:role] || Collaborator::ROLE_VIEWER).to_s
    raw_email = (params.dig(:collaborator, :email) || params[:email]).to_s.strip
    email   = raw_email.downcase
    user_id = (params.dig(:collaborator, :user_id) || params[:user_id]).presence

    invited_user =
      if user_id.present?
        User.find_by(id: user_id)
      elsif email.present?
        User.find_by("LOWER(email) = ?", email)
      end

    # --- Case A: invited user exists -> in-app collaborator request ---
    if invited_user
      if @event.collaborators.exists?(user_id: invited_user.id)
        redirect_to event_path(@event), alert: "That user is already a collaborator."
        return
      end

      @event.collaborators.create!(
        user: invited_user,
        role: role,
        status: Collaborator::STATUS_PENDING
      )

      redirect_to event_path(@event), notice: "#{invited_user.name} has been invited."
      return
    end

    # --- Case B: email not found -> create CollaborationInvite for email sending ---
    if email.blank?
      redirect_to event_path(@event), alert: "Please provide an email or select a friend."
      return
    end

    # avoid duplicate pending invites to same email for same event
    if CollaborationInvite.exists?(event: @event, invitee_email: email, status: "pending")
      redirect_to event_path(@event), alert: "An invite is already pending for #{email}."
      return
    end

    CollaborationInvite.create!(
      event: @event,
      inviter: current_user,
      invitee_email: email,
      role: role,
      status: "pending",
      sent_at: Time.current,
      expires_at: 14.days.from_now
    )

    # Your teammate will hook mail sending here later:
    # InviteMailer.collaboration_invite(invite).deliver_later

    redirect_to event_path(@event), notice: "Invite email sent to #{email}."
  end

  # PATCH /events/:event_id/collaborators/:id
  def update
    collaborator = @event.collaborators.find(params[:id])

    if params[:role].present? && collaborator.update(role: params[:role])
      redirect_to event_path(@event), notice: "Collaborator role updated."
    else
      redirect_to event_path(@event), alert: "Failed to update collaborator."
    end
  end

  # DELETE /events/:event_id/collaborators/:id
  def destroy
    collaborator = @event.collaborators.find(params[:id])
    name = collaborator.user.name
    collaborator.destroy
    redirect_to event_path(@event), notice: "#{name} removed from collaborators."
  end

  private

  # IMPORTANT:
  # - For create, use Event.all so we don't 404 before permission check
  # - For update/destroy, keep accessible_to
  def set_event
    scope = action_name == "create" ? Event.all : Event.accessible_to(current_user)
    @event = scope.find(params[:event_id])
  end
end
