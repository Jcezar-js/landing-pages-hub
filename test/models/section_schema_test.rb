require "test_helper"

class SectionSchemaTest < ActiveSupport::TestCase
  test "declares fields for every component type" do
    Section::COMPONENT_TYPES.each do |type|
      assert_not_empty SectionSchema.fields_for(type), "#{type} está sem campos no schema"
    end
  end

  test "hero declares titulo and subtitulo" do
    assert_equal %w[titulo subtitulo], SectionSchema.keys_for("hero")
  end

  test "field carries label, type and required flag" do
    titulo = SectionSchema.field("hero", "titulo")

    assert_equal "Título", titulo.label
    assert_equal :string, titulo.type
    assert titulo.required
  end

  test "list fields are declared as such" do
    assert_equal :list, SectionSchema.field("servicos", "itens").type
  end

  test "key? answers whether a key belongs to the type" do
    assert SectionSchema.key?("hero", "titulo")
    assert_not SectionSchema.key?("hero", "bio")
  end

  test "unknown component type has no fields" do
    assert_empty SectionSchema.fields_for("tipo_inexistente")
    assert_nil SectionSchema.field("tipo_inexistente", "titulo")
    assert_not SectionSchema.key?("tipo_inexistente", "titulo")
  end

  test "every declared type has a matching partial" do
    SectionSchema.component_types.each do |type|
      assert File.exist?(Rails.root.join("app/views/sections/_#{type}.html.erb")),
             "falta a partial app/views/sections/_#{type}.html.erb"
    end
  end

  # --- início: teste nosso (impede partial de furar o schema) ---
  # Section#value só protege quem passa por ele. Uma partial que volte a usar
  # section.data["chave"] direto recupera a quebra silenciosa que essa mudança
  # veio matar, e nenhum teste de renderização perceberia.
  test "no section partial reads data directly" do
    offenders = Dir[Rails.root.join("app/views/sections/_*.html.erb")].select do |path|
      File.read(path).include?("section.data")
    end

    assert_empty offenders.map { |p| Pathname.new(p).relative_path_from(Rails.root).to_s },
                 "use section.value(\"chave\") no lugar de section.data[\"chave\"]"
  end
  # --- fim: teste nosso ---
end
