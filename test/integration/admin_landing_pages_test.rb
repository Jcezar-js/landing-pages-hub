require "test_helper"

class AdminLandingPagesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in admins(:one)
  end

  test "new renders blank form" do
    client = clients(:two)
    client.landing_page.destroy

    get new_admin_client_landing_page_path(client)

    assert_response :success
  end

  test "create with a slug" do
    client = clients(:two)
    client.landing_page.destroy

    assert_difference("LandingPage.count", 1) do
      post admin_client_landing_page_path(client), params: { landing_page: { slug: "novo-slug" } }
    end

    assert_redirected_to edit_admin_client_landing_page_path(client)
  end

  test "create without a slug re-renders with error" do
    client = clients(:two)
    client.landing_page.destroy

    assert_no_difference("LandingPage.count") do
      post admin_client_landing_page_path(client), params: { landing_page: { slug: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "edit lists the existing blocks with a link to edit each one" do
    client = clients(:one)
    section = sections(:one)

    get edit_admin_client_landing_page_path(client)

    assert_response :success
    assert_select "a[href=?]", edit_admin_client_landing_page_section_path(client, section)
    assert_select "a[href=?]", new_admin_client_landing_page_section_path(client)
  end

  # --- início: teste nosso (o textarea de JSON não pode voltar) ---
  # Era por ele que uma chave digitada errada entrava no banco sem reclamar.
  # Bloco agora só é editado pela tela própria, com campos vindos do schema.
  test "the landing page form no longer edits blocks as raw JSON" do
    client = clients(:one)

    get edit_admin_client_landing_page_path(client)

    assert_select "textarea[name*=?]", "data", false
    assert_select "select[name*=?]", "component_type", false
  end
  # --- fim: teste nosso ---

  test "update changes the slug" do
    client = clients(:one)

    patch admin_client_landing_page_path(client), params: { landing_page: { slug: "slug-atualizado" } }

    assert_redirected_to edit_admin_client_landing_page_path(client)
    assert_equal "slug-atualizado", client.landing_page.reload.slug
  end

  test "destroy removes landing page and cascades sections" do
    client = clients(:one)

    assert_difference("Section.count", -1) do
      assert_difference("LandingPage.count", -1) do
        delete admin_client_landing_page_path(client)
      end
    end
  end
end
