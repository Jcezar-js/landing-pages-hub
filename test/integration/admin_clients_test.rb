require "test_helper"

class AdminClientsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in admins(:one)
  end

  test "index lists clients" do
    get admin_clients_path

    assert_response :success
  end

  # --- início: lógica nossa (busca, filtro de LP e paginação na listagem) ---
  test "index searches by name, case insensitive" do
    get admin_clients_path(q: "padaria")

    assert_match "Padaria da Esquina", @response.body
    assert_no_match(/Studio Fotografia Lua/, @response.body)
  end

  test "index searches by id" do
    get admin_clients_path(q: clients(:two).id.to_s)

    assert_match "Studio Fotografia Lua", @response.body
    assert_no_match(/Padaria da Esquina/, @response.body)
  end

  test "index filters clients that have a landing page" do
    get admin_clients_path(lp: "com")

    assert_match "Padaria da Esquina", @response.body
    assert_no_match(/Barbearia Central/, @response.body)
  end

  test "index filters clients without a landing page" do
    get admin_clients_path(lp: "sem")

    assert_match "Barbearia Central", @response.body
    assert_no_match(/Padaria da Esquina/, @response.body)
  end

  test "index paginates at 20 clients per page" do
    Client.destroy_all
    25.times { |i| Client.create!(name: format("Cliente %02d", i + 1)) }

    get admin_clients_path

    assert_match "Cliente 01", @response.body
    assert_match "Cliente 20", @response.body
    assert_no_match(/Cliente 21/, @response.body)

    get admin_clients_path(page: 2)

    assert_match "Cliente 21", @response.body
    assert_no_match(/Cliente 01/, @response.body)
  end

  test "index keeps search and filter while paginating" do
    Client.destroy_all
    25.times { |i| Client.create!(name: format("Cliente %02d", i + 1)) }

    get admin_clients_path(q: "Cliente", lp: "sem", page: 2)

    assert_match "Cliente 21", @response.body
    assert_no_match(/Cliente 01/, @response.body)
  end
  # --- fim: lógica nossa ---

  test "new renders form" do
    get new_admin_client_path

    assert_response :success
  end

  # Vindo da tela de prospecção: o form abre preenchido, mas nada é salvo até o
  # admin conferir e digitar o email (que o Places não fornece).
  test "new aceita valores de pré-preenchimento sem criar registro" do
    assert_no_difference("Client.count") do
      get new_admin_client_path(client: {
        name: "Barbearia Rio Grande",
        address: "R. Rio Grande, 138",
        phone: "(11) 94949-8118",
        website: "https://exemplo.com.br",
        google_place_id: "ChIJsemsite"
      })
    end

    assert_response :success
    assert_select "input[name=?][value=?]", "client[name]", "Barbearia Rio Grande"
    assert_select "input[name=?][value=?]", "client[phone]", "(11) 94949-8118"
    assert_select "input[name=?][value=?]", "client[google_place_id]", "ChIJsemsite"
  end

  test "create with valid params redirects to edit" do
    assert_difference("Client.count", 1) do
      post admin_clients_path, params: { client: { name: "Padaria da Esquina", email: "contato@padaria.example.com" } }
    end

    assert_redirected_to edit_admin_client_path(Client.last)
  end

  test "create with invalid params re-renders form" do
    assert_no_difference("Client.count") do
      post admin_clients_path, params: { client: { name: "", email: "contato@padaria.example.com" } }
    end

    assert_response :unprocessable_entity
  end

  test "edit renders form" do
    get edit_admin_client_path(clients(:one))

    assert_response :success
  end

  test "update with valid params redirects to edit" do
    patch admin_client_path(clients(:one)), params: { client: { name: "Novo Nome" } }

    assert_redirected_to edit_admin_client_path(clients(:one))
    assert_equal "Novo Nome", clients(:one).reload.name
  end

  test "update with invalid params re-renders form" do
    patch admin_client_path(clients(:one)), params: { client: { name: "" } }

    assert_response :unprocessable_entity
  end

  test "destroy removes client" do
    assert_difference("Client.count", -1) do
      delete admin_client_path(clients(:one))
    end

    assert_redirected_to admin_clients_path
  end
end
