require "test_helper"

class LandingPageTest < ActiveSupport::TestCase
  test "slug is required" do
    landing_page = LandingPage.new(client: clients(:three))

    assert_not landing_page.valid?
    assert_includes landing_page.errors[:slug], "can't be blank"
  end

  test "slug is unique" do
    landing_page = LandingPage.new(client: clients(:three), slug: landing_pages(:one).slug)

    assert_not landing_page.valid?
    assert_includes landing_page.errors[:slug], "has already been taken"
  end

  test "sections come back ordered by position" do
    landing_page = landing_pages(:one)
    landing_page.sections.create!(component_type: "mapa", data: { "endereco" => "Rua 2" }, position: 0)

    assert_equal [ 0, 1 ], landing_page.reload.sections.map(&:position)
  end

  test "destroying the landing page destroys its sections" do
    landing_page = landing_pages(:one)

    assert_difference("Section.count", -1) { landing_page.destroy }
  end
end
