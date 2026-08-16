require "test_helper"

class PlaceSearchTest < ActiveSupport::TestCase
  setup do
    @payload = JSON.parse(file_fixture("places_search_text.json").read)
  end

  test "parse devolve um hash por lugar do payload" do
    assert_equal 3, PlaceSearch.parse(@payload).size
  end

  test "parse mapeia os campos que a tela usa" do
    first = PlaceSearch.parse(@payload).first

    assert_equal "ChIJV3_YgpZZzpQRN6GXc15srh8", first[:place_id]
    assert_equal "Barbearia Vila Mariana - Goldens Barbearia", first[:name]
    assert_equal "R. Áurea, 326 - Vila Mariana, São Paulo - SP, 04015-070", first[:address]
    assert_equal "(11) 5539-5678", first[:phone]
    assert_equal "https://goldensbarbearia.com.br/", first[:website]
    assert_equal "https://maps.google.com/?cid=2282881214045462839", first[:maps_url]
    assert_equal 5, first[:rating]
    assert_equal 541, first[:rating_count]
    assert_equal "OPERATIONAL", first[:status]
  end

  # O lead que interessa é justamente o negócio sem site: o campo não vem no
  # payload, e a tela precisa distinguir isso de "site vazio".
  test "parse devolve nil quando website ou telefone não vieram" do
    results = PlaceSearch.parse(@payload)

    assert_nil results.second[:website]
    assert_equal "(11) 94949-8118", results.second[:phone]
    assert_nil results.third[:phone]
  end

  test "parse aceita payload sem nenhum resultado" do
    assert_equal [], PlaceSearch.parse({})
  end

  # O ambiente de teste usa :null_store, então o cache precisa ser trocado aqui
  # — senão todo cache_search viraria miss e o teste passaria por acidente.
  # Repetir a mesma busca é o caso comum (F5, botão voltar) e não pode custar.
  test "cached_search não chama a API de novo na mesma busca" do
    with_memory_cache do
      calls = 0

      stubbing(PlaceSearch, :search, ->(_query) { calls += 1; [ { place_id: "ChIJ1" } ] }) do
        2.times { PlaceSearch.cached_search("padaria em Osasco") }
      end

      assert_equal 1, calls
      assert_equal 1, PlaceSearchLog.this_month.count
    end
  end

  test "cached_search registra a busca com a quantidade de resultados" do
    with_memory_cache do
      stubbing(PlaceSearch, :search, ->(_query) { [ { place_id: "ChIJ1" }, { place_id: "ChIJ2" } ] }) do
        PlaceSearch.cached_search("padaria em Osasco")
      end
    end

    log = PlaceSearchLog.last
    assert_equal "padaria em Osasco", log.query
    assert_equal 2, log.results_count
  end

  # Erro de rede não pode contar como busca gasta nem virar resultado cacheado.
  test "cached_search não registra nem cacheia quando a API falha" do
    with_memory_cache do
      stubbing(PlaceSearch, :search, ->(_query) { raise PlaceSearch::Error, "Google respondeu 500" }) do
        assert_raises(PlaceSearch::Error) { PlaceSearch.cached_search("padaria em Osasco") }
      end

      assert_equal 0, PlaceSearchLog.count
      assert_nil Rails.cache.read("place_search/padaria em osasco")
    end
  end

  private

  # O ambiente de teste usa :null_store — sem trocar o store, todo cached_search
  # viraria miss e o teste de cache passaria por acidente.
  def with_memory_cache(&block)
    store = ActiveSupport::Cache::MemoryStore.new
    stubbing(Rails, :cache, -> { store }, &block)
  end
end
