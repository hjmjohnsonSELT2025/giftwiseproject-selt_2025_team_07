class MfaController < ApplicationController
  before_action :require_login
  before_action :require_password_login

  def setup
    if current_user.mfa_enabled?
      redirect_to edit_profile_path, alert: "MFA is already enabled"
      return
    end

    secret = ROTP::Base32.random
    session[:mfa_secret] = secret

    credential = MfaCredential.new(secret_key: secret)
    @provisioning_uri = credential.provisioning_uri(current_user.email)
    @secret_key = secret
  end

  def enable
    secret = session[:mfa_secret]
    code = params[:code]

    unless secret
      redirect_to setup_mfa_path, alert: "Please start the setup process again"
      return
    end

    unless code.present?
      redirect_to setup_mfa_path, alert: "Please enter the authentication code"
      return
    end

    totp = ROTP::TOTP.new(secret)

    if totp.verify(code, drift_behind: 30, drift_ahead: 30)
      current_user.create_mfa_credential!(
        secret_key: secret,
        enabled: true,
        enabled_at: Time.current
      )

      @backup_codes = BackupCode.generate_codes_for_user(current_user)
      session.delete(:mfa_secret)

      respond_to do |format|
        format.html { render :backup_codes }
        format.turbo_stream { render :backup_codes }
      end
    else
      redirect_to setup_mfa_path, alert: "Invalid code. Please try again."
    end
  end

  def disable
    unless current_user.mfa_enabled?
      redirect_to edit_profile_path, alert: "MFA is not enabled"
      return
    end

    current_user.mfa_credential.destroy
    current_user.backup_codes.destroy_all
    redirect_to edit_profile_path, notice: "MFA has been disabled successfully"
  end

  private

  def require_password_login
    unless current_user.password_login?
      redirect_to edit_profile_path, alert: "You must set a password before enabling MFA"
    end
  end
end