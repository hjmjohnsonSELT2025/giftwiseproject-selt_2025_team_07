# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{current_user.id}"
  end

  def unsubscribed
    stop_all_streams
  end

  def speak(data)
    message = current_user.sent_messages.create!(
      receiver_id: data['receiver_id'],
      body: data['message']
    )
  end
end
