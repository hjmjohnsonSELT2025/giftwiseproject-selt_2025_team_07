# frozen_string_literal: true

# app/serializers/message_serializer.rb
# Serializes Message model for ActionCable broadcasts
class MessageSerializer
  def initialize(message)
    @message = message
  end

  # Convert message to JSON format for real-time transmission
  def as_json
    {
      id: @message.id,
      body: @message.body,
      sender_id: @message.sender_id,
      receiver_id: @message.receiver_id,
      read: @message.read,
      created_at: @message.created_at.strftime('%l:%M %p'),
      sender_name: @message.sender.name
    }
  end
end