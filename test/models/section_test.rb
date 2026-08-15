require "test_helper"

class SectionTest < ActiveSupport::TestCase
  test "component_type must be one of COMPONENT_TYPES" do
    section = sections(:one)
    section.component_type = "tipo_inexistente"

    assert_not section.valid?
    assert_includes section.errors[:component_type], "is not included in the list"
  end

  test "valid component_type passes validation" do
    section = sections(:one)
    section.component_type = "hero"

    assert section.valid?
  end
end
