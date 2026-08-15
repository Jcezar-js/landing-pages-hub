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

  test "every block type renders without error" do
    Section::COMPONENT_TYPES.each do |type|
      client = Client.create!(name: "Smoke #{type}")
      landing_page = client.create_landing_page!(slug: "smoke-#{type}")
      landing_page.sections.create!(component_type: type, title: "T", data: {}, position: 1)

      get "/lp/#{landing_page.slug}"

      assert_response :success, "component_type #{type} falhou ao renderizar"
    end
  end
end
