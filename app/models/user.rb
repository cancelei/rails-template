# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  last_login_at          :datetime
#  locked_at              :datetime
#  name                   :string
#  phone                  :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           default("tourist")
#  session_token          :string
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_role                  (role)
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
class User < ApplicationRecord
  include ActionView::RecordIdentifier

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :lockable

  enum :role, { tourist: "tourist", guide: "guide", admin: "admin" }

  validates :role, presence: true, inclusion: { in: roles.keys }
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true, on: :create

  has_one :guide_profile, dependent: :destroy
  has_many :tours, foreign_key: :guide_id, inverse_of: :guide, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy

  # Active Storage attachment
  has_one_attached :avatar

  after_create :create_guide_profile_if_guide

  # Turbo Stream broadcasts for admin dashboard
  after_create_commit :broadcast_created_to_admin
  after_update_commit :broadcast_updated_to_admin

  def create_guide_profile_if_guide
    create_guide_profile if guide?
  end

  # Check if user has any confirmed bookings with the given guide for ENDED tours
  # Only tourists who have completed a tour can leave comments
  def has_booking_with_guide?(guide_user)
    return false unless guide_user&.guide?

    bookings.joins(:tour)
            .where(tours: { guide_id: guide_user.id, status: :done })
            .exists?(status: :confirmed)
  end

  # Get booking statistics with a specific guide
  def booking_stats_with_guide(guide_user)
    return nil unless guide_user&.guide?

    confirmed_bookings = bookings.joins(:tour)
                                 .where(tours: { guide_id: guide_user.id })
                                 .where(status: :confirmed)

    {
      total_bookings: confirmed_bookings.count,
      tours_participated: confirmed_bookings.select(:tour_id).distinct.count,
      last_tour: confirmed_bookings.order(created_at: :desc).first&.tour,
      total_spots: confirmed_bookings.sum(:spots)
    }
  end

  ##
  # The `session_token` attribute is used to build the Devise
  # `authenticatable_salt` so changing the `session_token` has the effect of
  # invalidating any existing sessions for the current user.
  #
  # This method is called by Users::SessionsController#destroy to make sure
  # that when a user logs out (i.e. destroys their session) then the session
  # cookie they had cannot be used again. This closes a security issue with
  # cookie based sessions.
  #
  # References
  #   * https://github.com/plataformatec/devise/issues/3031
  #   * http://maverickblogging.com/logout-is-broken-by-default-ruby-on-rails-web-applications/
  #   * https://makandracards.com/makandra/53562-devise-invalidating-all-sessions-for-a-user
  #
  def invalidate_all_sessions!
    update!(session_token: SecureRandom.hex(16))
  end

  ##
  # devise calls this method to generate a salt for creating the session
  # cookie. We override the built-in devise implementation (which comes from
  # the devise `authenticable` module - see link below) to also include our
  # `session_token` attribute. This means that whenever the session_token
  # changes, the user's session cookie will be invalidated.
  #
  # `session_token` is `nil` until the user has signed out once. That is fine
  # because we only care about making the `session_token` **different** after
  # they logout so that the cookie is invalidated.
  #
  # References
  #  * https://github.com/heartcombo/devise/blob/master/lib/devise/models/authenticatable.rb#L97-L98
  #
  def authenticatable_salt
    "#{super}#{session_token}"
  end

  # Active Storage helper methods
  def avatar_url(variant: :medium)
    return avatar_url_or_default unless avatar.attached?

    case variant
    when :thumbnail
      Rails.application.routes.url_helpers.url_for(avatar.variant(resize_to_limit: [50, 50]))
    when :medium
      Rails.application.routes.url_helpers.url_for(avatar.variant(resize_to_limit: [150, 150]))
    when :large
      Rails.application.routes.url_helpers.url_for(avatar.variant(resize_to_limit: [300, 300]))
    else
      Rails.application.routes.url_helpers.url_for(avatar)
    end
  rescue StandardError
    avatar_url_or_default
  end

  def avatar_url_or_default
    "https://ui-avatars.com/api/?name=#{URI.encode_www_form_component(name || email)}&size=150&background=random"
  end

  protected

  # For passwordless auth, we don't require password for tourists
  def password_required?
    !tourist?
  end

  def email_required?
    true
  end

  private

  def broadcast_created_to_admin
    # Broadcast to all admin users
    User.where(role: :admin).find_each do |admin|
      broadcast_prepend_to(
        "admin_users_#{admin.id}",
        target: "users_table_body",
        partial: "admin/users/user",
        locals: { user: self }
      )
    end
  end

  def broadcast_updated_to_admin
    User.where(role: :admin).find_each do |admin|
      broadcast_replace_to(
        "admin_users_#{admin.id}",
        target: dom_id(self),
        partial: "admin/users/user",
        locals: { user: self }
      )
    end
  end
end
