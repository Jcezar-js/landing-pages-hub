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

  test "data accepts JSON string and converts to Hash" do
    section = sections(:one)
    section.data = '{"titulo": "Novo título"}'

    assert_equal({ "titulo" => "Novo título" }, section.data)
  end

  test "data accepts Hash directly" do
    section = sections(:one)
    section.data = { "titulo" => "Direto" }

    assert_equal({ "titulo" => "Direto" }, section.data)
  end

  test "malformed JSON string adds error on data" do
    section = sections(:one)
    section.data = "{invalido"

    assert_not section.valid?
    assert_includes section.errors[:data], "precisa ser um JSON válido (ex.: {\"titulo\": \"texto\"})"
  end
end
