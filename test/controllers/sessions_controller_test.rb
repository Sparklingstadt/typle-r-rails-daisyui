require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "the sign-in page offers Sparklingstadt ID first, then GitHub, and keeps the way back" do
    get "/signin", params: { returnTo: "/records" }
    assert_response :success
    assert_select "form[action='/auth/sid'] + form[action='/auth/github']"
    assert_select "form[action='/auth/sid'] button[data-variant=primary].w-full", "Sparklingstadt IDでログイン"
    assert_select "form[action='/auth/github'] button[data-variant=outline].w-full", "GitHubでログイン"
    assert_select "form[action='/auth/sid'] input[name=origin][value='/records']"
    assert_select "form[action='/auth/github'] input[name=origin][value='/records']"
    assert_select "input[name=password]", false, "no ID and password"
    assert_select "a[href^='/signup'], a[href^='/forgot-password'], a[href^='/forgot-id']", false
    assert_select "[role=alert]", false
    get "/signin", params: { returnTo: "//evil.example/x" }
    assert_select "form[action='/auth/sid'] input[name=origin][value='/home']"
  end

  test "GitHub alone is the primary button, and with neither login the page says it is unavailable" do
    with_env("SID_CLIENT_SECRET" => nil) do
      get "/signin"
      assert_select "form[action='/auth/sid']", false
      assert_select "form[action='/auth/github'] button[data-variant=primary]", "GitHubでログイン"
    end
    with_env("SID_ISSUER" => nil, "GITHUB_CLIENT_ID" => nil) do
      get "/signin"
      assert_select "form[action^='/auth/']", false
      assert_select "p", "ログイン機能を利用できません。しばらくしてから再試行してください。"
    end
  end

  test "a failed login is one message" do
    get "/signin", params: { error: "1" }
    assert_select "[role=alert]", { count: 1, text: "ログインできませんでした。もう一度お試しください。" }
  end

  test "sign-in comes back to the page it was opened from, as typle-r's returnTo, and only to this site" do
    get "/play?list=1"
    assert_select "a[href='/signin?returnTo=%2Fplay'][data-return-href='/signin?returnTo=%2Fplay%3Flist%3D1']"
    sign_in_with_sid(origin: "/records")
    assert_redirected_to "/records"
    delete session_path
    sign_in_with_sid(origin: "//evil.example/x")
    assert_redirected_to "/home"
  end

  test "signs out" do
    sign_in_as users(:one)
    delete session_path
    assert_redirected_to root_path
    assert_empty cookies[:session_id]
    assert_not Session.exists?(user: users(:one))
  end

  test "a page for an account sends to sign-in with the way back" do
    get account_path
    assert_redirected_to "/signin?returnTo=%2Faccount"
  end

  test "the ID-and-password pages and actions are gone" do
    [[:get, "/signup"], [:post, "/registration"], [:get, "/forgot-password"], [:post, "/forgot-password"],
     [:get, "/reset-password"], [:put, "/reset-password"], [:get, "/forgot-id"], [:post, "/forgot-id"],
     [:get, "/verify-email"], [:get, "/email_confirmations/token"], [:post, "/session"]].each do |verb, path|
      send(verb, path)
      assert_response :not_found, "#{verb} #{path}"
    end
    sign_in_as users(:two)
    [[:patch, "/account/password"], [:post, "/account/verification"]].each do |verb, path|
      send(verb, path)
      assert_response :not_found, "#{verb} #{path}"
    end
  end

  test "an account that signed in with an ID and a password is kept, but cannot sign in" do
    # A bcrypt digest, as the ID-and-password login saved them.
    legacy = User.create!(login_id: "legacy", password_digest: "$2a$12$R9h/cIPz0gi.URNNX3kh2OPST9/PgBkqquzi.Ss7KIUgO2t0jWMUW")
    post "/session", params: { login_id: "legacy", password: "password123" }
    assert_response :not_found
    assert_nil cookies[:session_id].presence
    assert legacy.reload.password_digest.present?, "its data stays"
  end

  test "the account settings keep signing out of every device" do
    sign_in_as users(:one)
    get general_settings_path
    assert_select "#sessions-heading"
    assert_select "#account-heading", false
    assert_select "input[type=password]", false
    users(:one).sessions.create!
    delete sessions_account_path
    assert_redirected_to root_path
    assert_empty users(:one).sessions.reload
  end

  test "the development login is not offered outside development" do
    get "/signin"
    assert_select "form[action='/auth/local']", false
    post "/auth/local"
    assert_response :not_found
  end

  test "in development, LOCAL_DEVELOPMENT_LOGIN=1 opens the demo account from this machine, as typle-r's local login" do
    demo = User.create!(login_id: "demo")
    env = Rails.env
    Rails.env = "development"
    with_env("LOCAL_DEVELOPMENT_LOGIN" => "1") do
      get "/signin", params: { returnTo: "/records" }
      assert_select "form[action='/auth/local'] input[name=returnTo][value='/records']"
      post "/auth/local", params: { returnTo: "/records" }
      assert_redirected_to "/records"
      assert_equal demo, Session.order(:id).last.user
      post "/auth/local", env: { "REMOTE_ADDR" => "192.0.2.1" }
      assert_response :not_found, "not from another machine"
    end
    post "/auth/local"
    assert_response :not_found, "not without LOCAL_DEVELOPMENT_LOGIN=1"
  ensure
    Rails.env = env
  end

  test "GitHub sign-in makes an account, then signs in to it" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(provider: "github", uid: "42", info: { nickname: "Octo Cat" })
    get "/auth/github/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:github] }
    user = User.find_by(github_uid: "42")
    assert_equal "octo-cat", user.login_id
    assert_redirected_to home_path
    get home_path
    assert_select "span", "GitHubでログイン中"
    delete session_path
    assert_no_difference(-> { User.count }) do
      get "/auth/github/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:github] }
    end
  ensure
    OmniAuth.config.test_mode = false
  end

  private
    def with_env(values)
      saved = values.keys.index_with { ENV[_1] }
      values.each { |key, value| ENV[key] = value }
      yield
    ensure
      saved.each { |key, value| ENV[key] = value }
    end
end
