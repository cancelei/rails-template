module SystemHelpers
  def sign_in_user(user, password: "passwordpassword")
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: password
    click_button "Sign In"
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
