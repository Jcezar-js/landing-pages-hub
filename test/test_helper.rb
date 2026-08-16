ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # --- início: helper nosso ---
    # Minitest 6 tirou o `stub` do core (virou a gem minitest-mock). São 4 linhas
    # fazer o que a suíte precisa — trocar um método de classe durante o bloco —
    # e é isso que mantém os testes offline: nenhuma chamada real à Places API.
    def stubbing(owner, name, callable)
      original = owner.method(name)
      owner.define_singleton_method(name) { |*args| callable.call(*args) }
      yield
    ensure
      owner.define_singleton_method(name, original)
    end
    # --- fim: helper nosso ---
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
