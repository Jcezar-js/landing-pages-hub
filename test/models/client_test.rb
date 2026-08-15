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
end
