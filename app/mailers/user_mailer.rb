class UserMailer < ApplicationMailer
  def account_activation user
    @user = user
    mail to: user.email, subject: I18n.t("mail.active")
  end

  def password_reset user
    @user = user
    mail to: user.email, subject: I18n.t("mail.reset")
  end
end
