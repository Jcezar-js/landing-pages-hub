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

  # --- início: lógica nossa (raiz do site leva ao painel) ---
  test "root redirects to the admin panel" do
    get "/"

    assert_redirected_to "/admin"
    # 302, não 301: navegador não pode cachear pra sempre (a raiz pode virar
    # página pública depois).
    assert_response :found
  end

  test "guest hitting root ends up at the sign in page" do
    get "/"
    follow_redirect!

    assert_redirected_to new_admin_session_path
  end

  test "sign in page renders on its own layout, outside the admin shell" do
    get new_admin_session_path

    assert_response :success
    assert_select "div.admin-shell", count: 0
    assert_select "form[action=?]", new_admin_session_path
  end
  # --- fim: lógica nossa ---

  test "public sign up route does not exist" do
    get "/admins/sign_up"

    assert_response :not_found
  end
end
