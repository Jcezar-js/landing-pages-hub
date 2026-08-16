require "test_helper"

class AdminSectionsTest < ActionDispatch::IntegrationTest
  setup do
    @client = clients(:one)
    @landing_page = landing_pages(:one)
    @section = sections(:one)
    sign_in admins(:one)
  end

  test "requires authentication" do
    sign_out admins(:one)

    get new_admin_client_landing_page_section_path(@client)

    assert_redirected_to new_admin_session_path
  end

  # --- passo 1: escolher o tipo ---

  test "new without a component type asks only for the type" do
    get new_admin_client_landing_page_section_path(@client)

    assert_response :success
    assert_select "select[name=?]", "component_type"
    assert_select "input[name=?]", "section[data][titulo]", false
  end

  test "new with an unknown component type falls back to the type picker" do
    get new_admin_client_landing_page_section_path(@client, component_type: "tipo_inexistente")

    assert_response :success
    assert_select "select[name=?]", "component_type"
    assert_select "input[name=?]", "section[data][titulo]", false
  end

  # --- passo 2: preencher os campos daquele tipo ---

  test "new with a component type renders that type's fields" do
    get new_admin_client_landing_page_section_path(@client, component_type: "hero")

    assert_response :success
    assert_select "input[name=?]", "section[data][titulo]"
    assert_select "input[name=?]", "section[data][subtitulo]"
    assert_select "input[type=hidden][name=?][value=?]", "section[component_type]", "hero"
  end

  test "new renders a textarea for a list field" do
    get new_admin_client_landing_page_section_path(@client, component_type: "servicos")

    assert_response :success
    assert_select "textarea[name=?]", "section[data][itens]"
  end

  test "new never renders a raw JSON field" do
    get new_admin_client_landing_page_section_path(@client, component_type: "hero")

    assert_select "textarea[name=?]", "section[data]", false
  end

  # --- create ---

  test "create stores the fields under data" do
    assert_difference("Section.count", 1) do
      post admin_client_landing_page_sections_path(@client), params: {
        section: {
          component_type: "hero",
          title: "Abertura",
          data: { titulo: "Bem-vindo", subtitulo: "Sempre aberto" }
        }
      }
    end

    section = Section.order(:id).last
    assert_equal({ "titulo" => "Bem-vindo", "subtitulo" => "Sempre aberto" }, section.data)
    assert_redirected_to edit_admin_client_landing_page_path(@client)
  end

  test "create splits a list field into an array" do
    post admin_client_landing_page_sections_path(@client), params: {
      section: {
        component_type: "servicos",
        title: "Serviços",
        data: { itens: "Corte\r\nBarba" }
      }
    }

    assert_equal [ "Corte", "Barba" ], Section.order(:id).last.data["itens"]
  end

  test "create ignores a key that is not in the schema" do
    post admin_client_landing_page_sections_path(@client), params: {
      section: {
        component_type: "hero",
        title: "Abertura",
        data: { titulo: "Bem-vindo", titluo: "chave errada" }
      }
    }

    assert_equal({ "titulo" => "Bem-vindo" }, Section.order(:id).last.data)
  end

  test "create without a required field re-renders with an error" do
    assert_no_difference("Section.count") do
      post admin_client_landing_page_sections_path(@client), params: {
        section: { component_type: "hero", title: "Abertura", data: { titulo: "" } }
      }
    end

    assert_response :unprocessable_entity
    assert_select "input[name=?]", "section[data][titulo]"
  end

  test "create puts the new block last when position is blank" do
    post admin_client_landing_page_sections_path(@client), params: {
      section: { component_type: "mapa", title: "Onde estamos", data: { endereco: "Rua 1" } }
    }

    assert_equal @section.position + 1, Section.order(:id).last.position
  end

  # --- edit / update ---

  test "edit shows the stored values in named fields" do
    get edit_admin_client_landing_page_section_path(@client, @section)

    assert_response :success
    assert_select "input[name=?][value=?]", "section[data][titulo]", "Bem-vindo"
  end

  test "update rewrites a field" do
    patch admin_client_landing_page_section_path(@client, @section), params: {
      section: { data: { titulo: "Outro título" } }
    }

    assert_redirected_to edit_admin_client_landing_page_path(@client)
    assert_equal "Outro título", @section.reload.value("titulo")
  end

  test "update keeps stored keys the form does not know about" do
    @section.update_column(:data, { "titulo" => "Antigo", "chave_legada" => "não pode sumir" })

    patch admin_client_landing_page_section_path(@client, @section), params: {
      section: { data: { titulo: "Novo" } }
    }

    assert_equal "não pode sumir", @section.reload.data["chave_legada"]
  end

  test "update cannot change the component type" do
    patch admin_client_landing_page_section_path(@client, @section), params: {
      section: { component_type: "mapa", data: { titulo: "Ainda hero" } }
    }

    assert_equal "hero", @section.reload.component_type
  end

  test "update blanking a required field re-renders with an error" do
    patch admin_client_landing_page_section_path(@client, @section), params: {
      section: { data: { titulo: "" } }
    }

    assert_response :unprocessable_entity
    assert_equal "Bem-vindo", @section.reload.value("titulo")
  end

  # --- destroy ---

  test "destroy removes the block" do
    assert_difference("Section.count", -1) do
      delete admin_client_landing_page_section_path(@client, @section)
    end

    assert_redirected_to edit_admin_client_landing_page_path(@client)
  end

  # --- isolamento entre clientes ---

  test "cannot reach a section that belongs to another client" do
    outra = sections(:two)

    get edit_admin_client_landing_page_section_path(@client, outra)

    assert_response :not_found
  end

  # --- início: teste nosso (formulário sem o hash `data` inteiro) ---
  # Campo removido no navegador ou request montado na mão: não pode explodir,
  # tem que cair na validação normal de campo obrigatório.
  test "create without any data at all re-renders with an error" do
    assert_no_difference("Section.count") do
      post admin_client_landing_page_sections_path(@client), params: {
        section: { component_type: "hero", title: "Abertura" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "update without any data at all keeps the block content untouched" do
    patch admin_client_landing_page_section_path(@client, @section), params: {
      section: { title: "Só o título" }
    }

    assert_redirected_to edit_admin_client_landing_page_path(@client)
    assert_equal "Só o título", @section.reload.title
    assert_equal "Bem-vindo", @section.value("titulo")
  end
  # --- fim: teste nosso ---

  # --- início: testes nossos (achados da revisão de código) ---

  # 1. `update` assinalava title/position direto do params: request que só mexe
  # em `data` (o form de edição manda tudo, mas um PATCH parcial não) apagava o
  # título e zerava a posição, jogando o bloco pro fim da LP em silêncio.
  test "update touching only data keeps title and position" do
    patch admin_client_landing_page_section_path(@client, @section), params: {
      section: { data: { titulo: "Outro" } }
    }

    @section.reload
    assert_equal "MyString", @section.title
    assert_equal 1, @section.position
  end

  test "update with a blank position keeps the current one" do
    patch admin_client_landing_page_section_path(@client, @section), params: {
      section: { title: "Novo título", position: "", data: { titulo: "Outro" } }
    }

    assert_equal 1, @section.reload.position
  end

  test "update can still clear the optional title" do
    patch admin_client_landing_page_section_path(@client, @section), params: {
      section: { title: "", data: { titulo: "Outro" } }
    }

    assert_predicate @section.reload.title, :blank?
  end

  # 2. `data` chegando como escalar ou array estourava NoMethodError (500) no
  # `.permit!`, em vez de cair na validação.
  test "create with a scalar data param does not blow up" do
    assert_no_difference("Section.count") do
      post admin_client_landing_page_sections_path(@client), params: {
        section: { component_type: "hero", title: "Abertura", data: "não é hash" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create with an array data param does not blow up" do
    assert_no_difference("Section.count") do
      post admin_client_landing_page_sections_path(@client), params: {
        section: { component_type: "hero", title: "Abertura", data: [ "a", "b" ] }
      }
    end

    assert_response :unprocessable_entity
  end

  # 3. Hash aninhado num campo de texto passava batido pela validação (Hash não
  # é blank?) e era renderizado como inspect de Ruby na LP pública.
  test "a nested hash in a text field is rejected instead of stored" do
    assert_no_difference("Section.count") do
      post admin_client_landing_page_sections_path(@client), params: {
        section: { component_type: "hero", title: "Abertura", data: { titulo: { x: "1" } } }
      }
    end

    assert_response :unprocessable_entity
  end

  test "an array item list is trimmed like the textarea path" do
    post admin_client_landing_page_sections_path(@client), params: {
      section: { component_type: "servicos", title: "Serviços", data: { itens: [ " Corte ", "", "Barba" ] } }
    }

    assert_equal [ "Corte", "Barba" ], Section.order(:id).last.data["itens"]
  end
  # --- fim: testes nossos ---
end
