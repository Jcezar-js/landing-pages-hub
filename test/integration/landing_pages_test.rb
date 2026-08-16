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

  # --- início: teste nosso (rede de drift entre SectionSchema e as partials) ---
  # Preenche cada bloco com o que o schema declara e exige que o valor apareça na
  # página. Partial que lê chave fora do schema estoura em Section#value; partial
  # que simplesmente esquece um campo declarado cai no assert_includes.
  test "every block type renders the content declared in its schema" do
    Section::COMPONENT_TYPES.each do |type|
      data = sample_data_for(type)

      client = Client.create!(name: "Smoke #{type}")
      landing_page = client.create_landing_page!(slug: "smoke-#{type}")
      landing_page.sections.create!(component_type: type, title: "T", data: data, position: 1)

      get "/lp/#{landing_page.slug}"

      assert_response :success, "component_type #{type} falhou ao renderizar"

      data.each_value do |value|
        Array(value).each do |expected|
          assert_includes response.body, expected,
                          "#{type} não renderizou #{expected.inspect} declarado no schema"
        end
      end
    end
  end

  private

  def sample_data_for(component_type)
    SectionSchema.fields_for(component_type).to_h do |field|
      value = field.type == :list ? [ "#{field.key}-um", "#{field.key}-dois" ] : "#{field.key}-valor"
      [ field.key, value ]
    end
  end
  # --- fim: teste nosso ---
end
