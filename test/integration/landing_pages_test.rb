require "test_helper"

class LandingPagesTest < ActionDispatch::IntegrationTest
  test "visitor can view landing page without logging in" do
    get "/lp/#{landing_pages(:one).slug}"

    assert_response :success
  end

  test "unknown slug returns 404" do
    get "/lp/does-not-exist"

    assert_response :not_found
  end
end
