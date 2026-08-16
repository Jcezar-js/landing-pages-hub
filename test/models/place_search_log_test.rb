require "test_helper"

class PlaceSearchLogTest < ActiveSupport::TestCase
  test "this_month ignora buscas de meses anteriores" do
    PlaceSearchLog.create!(query: "padaria em Osasco", results_count: 3)
    PlaceSearchLog.create!(query: "barbearia em Osasco", results_count: 5, created_at: 40.days.ago)

    assert_equal 1, PlaceSearchLog.this_month.count
  end

  test "remaining desconta as buscas do mês" do
    PlaceSearchLog.create!(query: "padaria em Osasco", results_count: 3)

    assert_equal PlaceSearch::MONTHLY_LIMIT - 1, PlaceSearch.remaining
    assert_equal 1, PlaceSearch.used_this_month
  end

  # Freio de custo: passou do limite, remaining é 0 — nunca negativo, senão a
  # tela teria que tratar sinal e o `.zero?` do controller deixaria de valer.
  test "remaining nunca fica negativo" do
    rows = Array.new(PlaceSearch::MONTHLY_LIMIT + 1) do |i|
      { query: "busca #{i}", results_count: 0, created_at: Time.current, updated_at: Time.current }
    end
    PlaceSearchLog.insert_all(rows)

    assert_equal 0, PlaceSearch.remaining
  end
end
