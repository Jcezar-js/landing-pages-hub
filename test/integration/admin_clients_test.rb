require "test_helper"

class AdminClientsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in admins(:one)
  end

  test "index lists clients" do
    get admin_clients_path

    assert_response :success
  end

  test "new renders form" do
    get new_admin_client_path

    assert_response :success
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
