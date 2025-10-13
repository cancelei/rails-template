class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :lockable

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
end
