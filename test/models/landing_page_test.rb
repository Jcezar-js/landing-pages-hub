require "test_helper"

class LandingPageTest < ActiveSupport::TestCase
  test "creates section via nested attributes" do
    landing_page = landing_pages(:one)

    assert_difference("Section.count", 1) do
      landing_page.update(
        sections_attributes: [
          { component_type: "servicos", title: "Serviços", data: { titulo: "Nossos serviços" }, position: 2 }
        ]
      )
    end
  end

  test "rejects blank nested section" do
    landing_page = landing_pages(:one)

    assert_no_difference("Section.count") do
      landing_page.update(
        sections_attributes: [
          { component_type: "", title: "", data: nil, position: nil }
        ]
      )
    end
  end

  test "removes section via _destroy" do
    landing_page = landing_pages(:one)
    section = sections(:one)

    assert_difference("Section.count", -1) do
      landing_page.update(
        sections_attributes: [
          { id: section.id, _destroy: "1" }
        ]
      )
    end
  end
end
