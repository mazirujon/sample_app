class PasswordResetsController < ApplicationController
  before_action :load_user, :valid_user, :check_expiration,
    only: %i(edit update)

  def new; end

  def create
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = t "flash.email_reset"
      redirect_to root_path
    else
      flash.now[:danger] = t "flash.email_nfound"
      render :new
    end
  end

  def update
    if params[:user][:password].empty? # C3
      @user.errors.add(:password, t("flash.empty"))
      render :edit
    elsif @user.update_attributes(user_params) # C4
      log_in @user
      flash[:success] = t "flash.pass_reset"
      redirect_to @user
    else
      render :edit # C2
    end
  end

  def edit; end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def load_user
    @user = User.find_by email: params[:email]
    return if @user
    flash[:danger] = t "messenger.user_nill"
    redirect_to root_path
  end

  # Confirms a valid user.
  def valid_user
    return if @user&.activated? && @user.authenticated?(:reset, params[:id])
    redirect_to root_path
  end

  def check_expiration
    return unless @user.password_reset_expired?
    flash[:danger] = t "flash.pass_expired"
    redirect_to new_password_reset_url
  end
end
