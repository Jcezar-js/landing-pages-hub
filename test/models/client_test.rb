require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "name is required" do
    client = Client.new(name: "", email: "a@example.com")
    assert_not client.valid?
    assert_includes client.errors[:name], "can't be blank"
  end

  test "valid with name and email" do
    client = Client.new(name: "Padaria da Esquina", email: "contato@padaria.example.com")
    assert client.valid?
  end

  # Cliente cadastrado à mão não tem place_id — a unicidade não pode barrar o
  # segundo cadastro manual, só o mesmo negócio do Google entrando duas vezes.
  test "google_place_id é opcional e único quando presente" do
    Client.create!(name: "Barbearia A", google_place_id: "ChIJabc")

    assert Client.new(name: "Cliente manual").valid?
    assert Client.new(name: "Outro manual").valid?

    duplicado = Client.new(name: "Barbearia A de novo", google_place_id: "ChIJabc")
    assert_not duplicado.valid?
    assert_includes duplicado.errors[:google_place_id], "has already been taken"
  end
end
