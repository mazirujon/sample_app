class User < ApplicationRecord
  attr_accessor :remember_token, :activation_token

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  before_save :downcase_email
  before_create :create_activation_digest

  has_secure_password

  validates :name, presence: true, length: {maximum: Settings.MAX_LENG_NAME}
  validates :email, presence: true, length: {maximum: Settings.MAX_LENG_MAIL},
                    format: {with: VALID_EMAIL_REGEX},
                    uniqueness: {case_sensitive: false}
  validates :password, presence: true,
                        length: {minimum: Settings.MIN_LENG_PASSWORD},
                        allow_nil: true
  class << self
    def digest string
      cost = if ActiveModel::SecurePassword.min_cost
               BCrypt::Engine::MIN_COST
             else
               BCrypt::Engine.cost
             end
      BCrypt::Password.create string, cost: cost
    end

    def new_token
      SecureRandom.urlsafe_base64
    end
  end

  def remember
    self.remember_token = User.new_token
    update_attribute :remember_digest, User.digest(remember_token)
  end

  def authenticated? attribute, token
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password? token
  end

  def forget
    update_attribute :remember_digest, nil
  end

  # Activates an account.
  def activate
    update_attribute(:activated, true)
    update_attribute(:activated_at, Time.zone.now)
  end

  # Sends activation email.
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  private

  # Converts email to all lower-case.
  def downcase_email
    self.email = email.downcase
  end

  # Creates and assigns the activation token and digest.
  def create_activation_digest
    self.activation_token  = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
