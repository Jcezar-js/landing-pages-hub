require "test_helper"

class AdminAuthenticationTest < ActionDispatch::IntegrationTest
  test "guest redirected to sign in when visiting admin area" do
    get "/admin"

    assert_redirected_to new_admin_session_path
  end

  test "authenticated admin can visit admin area" do
    sign_in admins(:one)

    get "/admin"

    assert_response :success
  end

  test "public sign up route does not exist" do
    get "/admins/sign_up"

    assert_response :not_found
  end
end
