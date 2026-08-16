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

  test "COMPONENT_TYPES comes from the schema" do
    assert_equal SectionSchema.component_types, Section::COMPONENT_TYPES
  end

  # --- Section#value: a rede que pega chave errada ---

  test "value returns the stored content for a key in the schema" do
    section = sections(:one)

    assert_equal "Bem-vindo", section.value("titulo")
  end

  test "value returns nil when the key is in the schema but was never filled" do
    section = sections(:one)

    assert_nil section.value("subtitulo")
  end

  test "value raises when the key does not belong to the component type" do
    section = sections(:one)

    error = assert_raises(ArgumentError) { section.value("bio") }
    assert_match "bio", error.message
    assert_match "hero", error.message
  end

  # --- campos obrigatórios ---

  test "missing required field invalidates the section" do
    section = sections(:one)
    section.data = {}

    assert_not section.valid?
    assert_includes section.errors[:titulo], "não pode ficar em branco"
  end

  test "blank string in a required field invalidates the section" do
    section = sections(:one)
    section.data = { "titulo" => "   " }

    assert_not section.valid?
    assert_includes section.errors[:titulo], "não pode ficar em branco"
  end

  test "empty list in a required list field invalidates the section" do
    section = sections(:two)
    section.component_type = "servicos"
    section.data = { "itens" => [] }

    assert_not section.valid?
    assert_includes section.errors[:itens], "não pode ficar em branco"
  end

  test "optional field may stay blank" do
    section = sections(:one)
    section.data = { "titulo" => "Só o título" }

    assert section.valid?
  end

  # --- assign_data: whitelist pelo schema, merge e coerção ---

  test "assign_data writes fields declared in the schema" do
    section = sections(:one)
    section.assign_data("titulo" => "Novo", "subtitulo" => "Sub")

    assert_equal({ "titulo" => "Novo", "subtitulo" => "Sub" }, section.data)
  end

  test "assign_data ignores keys outside the schema" do
    section = sections(:one)
    section.assign_data("titulo" => "Novo", "titluo" => "erro de digitação")

    assert_equal({ "titulo" => "Novo" }, section.data)
  end

  test "assign_data preserves stored keys it was not asked to change" do
    section = sections(:one)
    section.update_column(:data, { "titulo" => "Antigo", "chave_legada" => "não pode sumir" })
    section.reload.assign_data("titulo" => "Novo")

    assert_equal "Novo", section.data["titulo"]
    assert_equal "não pode sumir", section.data["chave_legada"]
  end

  test "assign_data splits a list field on line breaks" do
    section = sections(:one)
    section.component_type = "servicos"
    section.assign_data("itens" => "Corte\r\nBarba\r\nHidratação")

    assert_equal [ "Corte", "Barba", "Hidratação" ], section.data["itens"]
  end

  test "assign_data drops blank lines from a list field" do
    section = sections(:one)
    section.component_type = "servicos"
    section.assign_data("itens" => "Corte\n\n   \nBarba\n")

    assert_equal [ "Corte", "Barba" ], section.data["itens"]
  end

  test "assign_data accepts an already split list" do
    section = sections(:one)
    section.component_type = "servicos"
    section.assign_data("itens" => [ "Corte", "Barba" ])

    assert_equal [ "Corte", "Barba" ], section.data["itens"]
  end

  test "data still accepts a Hash directly" do
    section = sections(:one)
    section.data = { "titulo" => "Direto" }

    assert_equal({ "titulo" => "Direto" }, section.data)
  end

  # 4. `value` comparava a chave por igualdade de String: um símbolo era
  # rejeitado com mensagem que listava a própria chave como válida.
  test "value accepts a symbol key" do
    assert_equal "Bem-vindo", sections(:one).value(:titulo)
  end

  test "assign_data accepts symbol keys" do
    section = sections(:one)
    section.assign_data(titulo: "Por símbolo")

    assert_equal "Por símbolo", section.data["titulo"]
  end
end
