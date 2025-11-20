class PasswordResetMailer < ApplicationMailer
  default from: 'noreply@mygiftwise.online'

  def reset_email(user, token)
    @user = user
    @reset_url = reset_password_url(token: token.token)

    mail(
      to: @user.email,
      subject: 'Reset Your GiftWise Password'
    )
  end
end