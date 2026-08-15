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

  test "old browser can still view landing page" do
    get "/lp/#{landing_pages(:one).slug}", headers: { "User-Agent" => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" }

    assert_response :success
  end

  test "loja template renders the loja block" do
    get "/lp/#{landing_pages(:one).slug}"

    assert_select "div.landing-page--loja"
  end

  test "pessoal template renders the pessoal block" do
    get "/lp/#{landing_pages(:two).slug}"

    assert_select "div.landing-page--pessoal"
  end
end
