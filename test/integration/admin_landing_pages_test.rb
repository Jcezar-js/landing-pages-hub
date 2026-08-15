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

  test "create with valid nested sections" do
    client = clients(:two)
    client.landing_page.destroy

    assert_difference [ "LandingPage.count", "Section.count" ], 1 do
      post admin_client_landing_page_path(client), params: {
        landing_page: {
          slug: "novo-slug",
          sections_attributes: {
            "0" => { component_type: "hero", title: "Hero", data: '{"titulo":"Bem-vindo"}', position: 1 }
          }
        }
      }
    end

    assert_redirected_to edit_admin_client_landing_page_path(client)
  end

  test "create ignores blank nested section row" do
    client = clients(:two)
    client.landing_page.destroy

    assert_difference("LandingPage.count", 1) do
      assert_no_difference("Section.count") do
        post admin_client_landing_page_path(client), params: {
          landing_page: {
            slug: "outro-slug",
            sections_attributes: {
              "0" => { component_type: "", title: "", data: "", position: "" }
            }
          }
        }
      end
    end
  end

  test "create with invalid JSON re-renders with error" do
    client = clients(:two)
    client.landing_page.destroy

    assert_no_difference("LandingPage.count") do
      post admin_client_landing_page_path(client), params: {
        landing_page: {
          slug: "invalido",
          sections_attributes: {
            "0" => { component_type: "hero", title: "Hero", data: "{invalido", position: 1 }
          }
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "edit shows existing sections" do
    client = clients(:one)

    get edit_admin_client_landing_page_path(client)

    assert_response :success
  end

  test "update changes slug and edits existing section and adds new one" do
    client = clients(:one)
    section = sections(:one)

    assert_difference("Section.count", 1) do
      patch admin_client_landing_page_path(client), params: {
        landing_page: {
          slug: "slug-atualizado",
          sections_attributes: {
            "0" => { id: section.id, title: "Título editado" },
            "1" => { component_type: "servicos", title: "Novo bloco", data: '{"titulo":"Serviços"}', position: 2 }
          }
        }
      }
    end

    assert_redirected_to edit_admin_client_landing_page_path(client)
    assert_equal "slug-atualizado", client.landing_page.reload.slug
    assert_equal "Título editado", section.reload.title
  end

  test "update with _destroy removes section" do
    client = clients(:one)
    section = sections(:one)

    assert_difference("Section.count", -1) do
      patch admin_client_landing_page_path(client), params: {
        landing_page: {
          sections_attributes: {
            "0" => { id: section.id, _destroy: "1" }
          }
        }
      }
    end
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
