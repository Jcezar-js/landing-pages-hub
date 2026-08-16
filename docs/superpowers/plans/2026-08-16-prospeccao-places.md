# Prospecção de clientes via Google Places API (New) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:subagent-driven-development (recomendado) ou superpowers:executing-plans para implementar este plano task a task. Passos usam checkbox (`- [ ]`) pra tracking.

## Context

O painel admin hoje só enxerga clientes já cadastrados. Não existe caminho no produto para *encontrar* um cliente novo — a prospecção acontece fora da ferramenta, e o cadastro é 100% digitado à mão.

Este plano adiciona uma aba própria de **prospecção**: o admin busca negócios de uma região pela Google Places API (New), vê a lista com link para o Google Maps, identifica quem ainda não tem site (o lead ideal para uma landing page) e, com um clique, abre o formulário de novo cliente já pré-preenchido.

A tarefa do Notion "📍 Autocomplete de Client via Google Places API (New)" (`3bd0f74b846e81eaa197c2c5e1981e5e`, não iniciada) é **absorvida por este plano**. Ela previa um endpoint JSON separado só para autocompletar o form de `Client`; com a tela de prospecção, o resultado da busca já está em mãos e o pré-preenchimento vira um link com query params — sem endpoint extra, sem segunda chamada paga, sem JS.

Decisões fechadas com o usuário antes deste plano:

- **Worktree sai de `admin-ui-pico`**, não da `main`. A sidebar do painel, o `layouts/admin.html.erb` e o Pico CSS só existem nessa branch (commits `37e69f9`/`13f6c10`, ainda não mergeados). Sem essa base não há menu onde encaixar a opção nova.
- **Key da API via `dotenv-rails`** (grupo `development`/`test`), lendo `GOOGLE_MAPS_API_KEY` do `.env` que já existe e já está no `.gitignore`. `Rails.application.credentials` foi descartado: não existe `config/master.key` no repo e o `credentials.yml.enc` atual não abre — usá-lo exigiria recriar credenciais e `secret_key_base`. Em produção o Kamal já injeta variável de ambiente, então o mesmo `ENV` serve nos dois lados.
- **Busca por texto livre (`places:searchText`)**, não `searchNearby`. Um campo só ("barbearia em Vila Mariana, São Paulo"), uma chamada. `searchNearby` exigiria latitude/longitude — ou digitadas à mão, ou uma chamada extra paga à Geocoding API, ou um mapa com JS.
- **Nada de Places é persistido como cache.** Os Termos do Google proíbem armazenar conteúdo de Places além de 30 dias, com exceção do `place_id`. Resultado de busca vive em `Rails.cache` com TTL de 12h; o que vira registro permanente é só o `Client` que o admin criar e conferir — dado de CRM nosso, não cópia do índice do Google.

## Architecture

Três peças novas, nenhuma camada de serviço:

**`PlaceSearch`** (`app/models/place_search.rb`) — PORO que fala com a API. Uma chamada `POST places:searchText` via `Net::HTTP` da stdlib (nenhuma gem de HTTP client), com `X-Goog-FieldMask` explícito, timeouts curtos e parsing do JSON para um array de `Hash`. Fica em `app/models` porque é objeto de domínio, não um "service layer" novo — a convenção do projeto (CLAUDE.md) é MVC puro.

**`PlaceSearchLog`** (model + tabela) — uma linha por chamada *real* à API. É o contador que a tela exibe e o freio do limite mensal. Precisa ser tabela, não `Rails.cache`: é guarda de custo, e cache pode ser esvaziado a qualquer momento, zerando o freio em silêncio.

**`Admin::ProspectsController#index`** — GET com `?q=`. Sem `q`, só o formulário. Com `q`, consulta `Rails.cache` antes de qualquer coisa: **cache hit não chama a API e não incrementa o contador**. Isso não é otimização, é proteção de custo — sem ele, F5 e botão voltar do navegador viram requisições pagas.

Fluxo de custo, do mais barato ao mais caro:

```
q vazio            → nada acontece
cache hit (12h)    → resultado da memória, 0 request, contador parado
limite estourado   → aviso na tela, nenhuma chamada
cache miss         → 1 request paga + 1 linha em place_search_logs
```

O pré-preenchimento do cadastro é `link_to new_admin_client_path(client: { ... })` — o `Admin::ClientsController#new` passa a aceitar esses params e monta o `Client.new` com eles. O admin confere, digita o `email` (que o Places não fornece) e salva.

## Tech Stack

Rails 8, Devise (reaproveitado sem mudança), `Net::HTTP` (stdlib), `Rails.cache` (solid_cache, já instalado), PostgreSQL, Minitest + fixtures. Uma gem nova: `dotenv-rails` (development/test). Sem WebMock: o parsing é testado direto sobre um payload real salvo em `test/fixtures/files/`, e os testes de integração fazem stub de `PlaceSearch.search`.

### Custo real (verificado em 2026-08-16)

`websiteUri`, `nationalPhoneNumber`, `rating` e `userRatingCount` são campos do **SKU Enterprise** do Text Search: **1.000 requests grátis/mês**, depois US$ 35,00 por 1.000 (~US$ 0,035 por busca). O SKU Pro tem 5.000 grátis, mas não inclui `websiteUri` — e é justamente a ausência de site que identifica o lead. O SKU é escolhido pelo campo mais caro do field mask, então `rating`/`userRatingCount` entram de graça na conta e ficam.

Limite default do app: **500 buscas/mês** (`PLACES_MONTHLY_LIMIT`, sobrescrevível por ENV), metade do teto gratuito. Aviso visual a partir de 80%.

Fontes: [Nearby/Text Search — SKUs por campo](https://developers.google.com/maps/documentation/places/web-service/nearby-search), [Pricing list](https://developers.google.com/maps/billing-and-pricing/pricing).

### Field mask

```
places.id,places.displayName,places.formattedAddress,places.nationalPhoneNumber,
places.websiteUri,places.googleMapsUri,places.rating,places.userRatingCount,places.businessStatus
```

`places.photos` fica **fora** de propósito: cada foto exigiria uma segunda requisição paga (`/media`) e o campo sozinho inflou o payload de teste em ~70%.

## Spec

- Notion — Tarefa absorvida: https://app.notion.com/p/3bd0f74b846e81eaa197c2c5e1981e5e (mapeamento de campos Places → `Client` sai daqui)
- Notion — Decisões já tomadas: https://app.notion.com/p/3bc0f74b846e8000a362d658afb8ec9a
- Google — Text Search (New): https://developers.google.com/maps/documentation/places/web-service/text-search
- `CLAUDE.md` (raiz do repo)

## Global Constraints

- TDD estrito: RED → GREEN → refactor em cada step. Ver o teste falhar é parte do passo.
- Trabalhar em `.claude/worktrees/prospeccao-places` (branch `prospeccao-places`, criada a partir de `admin-ui-pico`). Todo `bin/rails test`, `bin/rubocop` e commit roda lá dentro.
- **Nenhum teste faz chamada HTTP real.** Teste que vaza requisição queima quota e falha sem rede.
- `ApplicationController` já tem `before_action :authenticate_admin!` — não duplicar teste de acesso não autenticado (coberto em `test/integration/admin_authentication_test.rb`).
- Nada de dado do Places persistido além do `place_id` e do que o admin conscientemente salvar como `Client`.
- Todo trecho nosso abre com `# --- início: lógica nossa (X) ---`.
- Checklist obrigatório antes do commit (CLAUDE.md): (1) testes + `bin/rubocop` limpos; (2) `/ponytail-review` no diff, resolver ou justificar cada achado; (3) Notion nos dois níveis; (4) commit local. Push/merge é decisão do usuário.

---

### Task 1: `PlaceSearch` — chamada e parsing da API

**Files:**
- Modify: `Gemfile`, `Gemfile.lock`
- Create: `app/models/place_search.rb`
- Create: `test/fixtures/files/places_search_text.json`
- Test: `test/models/place_search_test.rb`

**Interfaces:**
- Consumes: `ENV["GOOGLE_MAPS_API_KEY"]`.
- Produces: `PlaceSearch.parse(payload)` → `Array<Hash>` com `:place_id, :name, :address, :phone, :website, :maps_url, :rating, :rating_count, :status`; `PlaceSearch.search(query)`; `PlaceSearch::Error`.

- [ ] **Step 1: RED — parsing do payload**

`test/models/place_search_test.rb`: carrega `test/fixtures/files/places_search_text.json` (payload real, ~3 lugares, um deles **sem** `websiteUri` e um sem `nationalPhoneNumber`), passa por `PlaceSearch.parse` e verifica: quantidade de resultados, `:name` vindo de `displayName.text`, `:maps_url` vindo de `googleMapsUri`, e `:website`/`:phone` `nil` quando o campo não veio. Rodar — FALHA, classe não existe.

- [ ] **Step 2: GREEN — `PlaceSearch.parse` + `search`**

Criar `app/models/place_search.rb`. `parse` mapeia `payload["places"]` para hashes. `search(query)` monta o POST:

```ruby
# app/models/place_search.rb
ENDPOINT = URI("https://places.googleapis.com/v1/places:searchText")

def self.search(query)
  key = ENV["GOOGLE_MAPS_API_KEY"].presence or raise Error, "GOOGLE_MAPS_API_KEY não configurada"

  response = Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true,
                             open_timeout: 3, read_timeout: 8) do |http|
    http.post(ENDPOINT.path,
              { textQuery: query, pageSize: 20, languageCode: "pt-BR", regionCode: "BR" }.to_json,
              "Content-Type" => "application/json",
              "X-Goog-Api-Key" => key,
              "X-Goog-FieldMask" => FIELD_MASK)
  end

  raise Error, "Google respondeu #{response.code}" unless response.is_a?(Net::HTTPSuccess)

  parse(JSON.parse(response.body))
rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, JSON::ParserError => e
  raise Error, e.class.name
end
```

Adicionar `gem "dotenv-rails"` ao grupo `development, :test` do Gemfile e rodar `bundle install`. Rodar o teste — VERDE.

> Corpo de erro do Google traz `error.message` legível; propagar só o código evita vazar a key em log caso ela apareça na mensagem.

---

### Task 2: `PlaceSearchLog` — contador e limite mensal

**Files:**
- Create: `db/migrate/*_create_place_search_logs.rb`, `app/models/place_search_log.rb`
- Modify: `db/schema.rb`, `app/models/place_search.rb`
- Test: `test/models/place_search_log_test.rb`

**Interfaces:**
- Produces: `PlaceSearchLog.this_month`, `PlaceSearch::MONTHLY_LIMIT`, `PlaceSearch.used_this_month`, `PlaceSearch.remaining`.

- [ ] **Step 3: RED — contagem do mês corrente**

`test/models/place_search_log_test.rb`: cria log de hoje e outro com `created_at: 40.days.ago`; `PlaceSearchLog.this_month.count` deve ser 1. Segundo teste: com `MONTHLY_LIMIT` logs no mês, `PlaceSearch.remaining` é 0. FALHA — model não existe.

- [ ] **Step 4: GREEN — migration + model**

Tabela `place_search_logs`: `query:string`, `results_count:integer`, timestamps, índice em `created_at`. Model com `scope :this_month, -> { where(created_at: Time.current.all_month) }`. Em `PlaceSearch`:

```ruby
MONTHLY_LIMIT = Integer(ENV.fetch("PLACES_MONTHLY_LIMIT", 500))

def self.used_this_month = PlaceSearchLog.this_month.count
def self.remaining = [ MONTHLY_LIMIT - used_this_month, 0 ].max
```

Rodar — VERDE.

- [ ] **Step 5: RED — cache impede chamada e log duplicados**

`PlaceSearch.cached_search(query)`: primeira chamada com stub de `search` grava log; segunda chamada com a mesma query **não** chama `search` de novo e **não** cria log. O ambiente de teste usa `:null_store`, então o teste troca o store no setup:

```ruby
setup { @store = ActiveSupport::Cache::MemoryStore.new }

test "segunda busca igual não chama a API" do
  Rails.stub(:cache, @store) do
    calls = 0
    PlaceSearch.stub(:search, ->(_q) { calls += 1; [] }) do
      2.times { PlaceSearch.cached_search("padaria em Osasco") }
    end
    assert_equal 1, calls
    assert_equal 1, PlaceSearchLog.this_month.count
  end
end
```

FALHA — `cached_search` não existe.

- [ ] **Step 6: GREEN — `cached_search`**

```ruby
# Cache não é performance aqui, é freio de custo: sem ele, F5 e botão voltar
# do navegador viram requisição paga. 12h fica bem abaixo do teto de 30 dias
# que os Termos do Google permitem para conteúdo de Places.
def self.cached_search(query)
  Rails.cache.fetch("place_search/#{query.downcase.strip}", expires_in: 12.hours) do
    results = search(query)
    PlaceSearchLog.create!(query: query, results_count: results.size)
    results
  end
end
```

Rodar — VERDE. (`Error` levantado dentro do bloco não grava cache nem log: o `fetch` não escreve quando o bloco levanta.)

---

### Task 3: colunas de prospecção em `Client`

**Files:**
- Create: `db/migrate/*_add_places_fields_to_clients.rb`
- Modify: `app/models/client.rb`, `db/schema.rb`, `app/views/admin/clients/_form.html.erb`
- Test: `test/models/client_test.rb`

**Interfaces:**
- Produces: `Client#google_place_id`, `#address`, `#phone`, `#website`.

- [ ] **Step 7: RED — `google_place_id` opcional e único quando presente**

`test/models/client_test.rb`: dois clients sem `google_place_id` são válidos (`allow_nil`); um segundo client com `google_place_id` já usado é inválido. FALHA — colunas não existem.

- [ ] **Step 8: GREEN — migration + validação**

Migration adiciona `google_place_id:string` (índice único), `address:string`, `phone:string`, `website:string` a `clients`. No model: `validates :google_place_id, uniqueness: true, allow_nil: true`. Mapeamento conforme a tabela da tarefa do Notion. Adicionar os quatro campos ao `_form.html.erb` do cliente. Rodar — VERDE.

---

### Task 4: tela de prospecção

**Files:**
- Modify: `config/routes.rb`, `app/views/layouts/admin.html.erb`, `app/assets/stylesheets/admin.css`
- Create: `app/controllers/admin/prospects_controller.rb`, `app/views/admin/prospects/index.html.erb`
- Test: `test/integration/admin_prospects_test.rb`

**Interfaces:**
- Consumes: `PlaceSearch.cached_search`, `PlaceSearch.remaining`, `PlaceSearch.used_this_month`.
- Produces: rota `admin_prospects_path`, item "Prospecção" na sidebar.

- [ ] **Step 9: RED — testes de integração da tela**

`test/integration/admin_prospects_test.rb`, com `sign_in admins(:one)` no setup e stub de `PlaceSearch.cached_search` (nenhum teste toca a rede):

1. `GET /admin/prospects` sem `q` → 200, formulário na tela, `cached_search` **não** é chamado (stub que falha o teste se chamado).
2. Com `q` → 200, nome e endereço do resultado aparecem, e o link do Google Maps (`maps_url`) está na página.
3. Resultado sem `website` aparece marcado como "sem site"; com `?sem_site=1` os que têm site somem da listagem.
4. Resultado cujo `place_id` já existe em `clients` aparece marcado como "já cadastrado", com link para editar o cliente.
5. Com `PlaceSearch::MONTHLY_LIMIT` logs no mês → aviso de limite na tela e `cached_search` **não** é chamado.
6. `PlaceSearch::Error` levantado no stub → 200 com mensagem de erro, sem exceção vazando.

Rodar — FALHA, rota não existe.

- [ ] **Step 10: GREEN — rota, controller e view**

```ruby
# config/routes.rb (dentro do namespace :admin)
resources :prospects, only: %i[index]
```

```ruby
# app/controllers/admin/prospects_controller.rb
# --- início: lógica nossa (busca de prospects na Google Places API) ---
class Admin::ProspectsController < ApplicationController
  layout "admin"

  def index
    @remaining = PlaceSearch.remaining
    @used = PlaceSearch.used_this_month
    @query = params[:q].to_s.strip
    return if @query.blank? || @remaining.zero?

    @results = PlaceSearch.cached_search(@query)
    @results = @results.reject { |r| r[:website] } if params[:sem_site].present?
    @registered = Client.where(google_place_id: @results.map { |r| r[:place_id] })
                        .pluck(:google_place_id, :id).to_h
  rescue PlaceSearch::Error => e
    flash.now[:alert] = "Busca indisponível agora (#{e.message}). Tente de novo em instantes."
  end
end
```

View: formulário com um campo de texto e o checkbox "só quem não tem site", tabela de resultados (nome, endereço, telefone, nota, site ou "— sem site", link "Ver no Maps" com `target: "_blank", rel: "noopener"`), e por linha o botão "Cadastrar como cliente" (Task 5) ou o aviso "já cadastrado" com link de edição.

Aviso de custo, discreto, em `<small>` abaixo do campo:

> Cada busca nova consome 1 requisição paga da Google (1.000 gratuitas por mês). Repetir a mesma busca em até 12h não gera cobrança. **`@used` de `MONTHLY_LIMIT`** buscas usadas neste mês.

Quando `@remaining` for 0, o texto vira aviso de limite atingido e o botão de busca fica desabilitado. A partir de 80% do limite, o contador ganha destaque (classe CSS em `admin.css`, sem JS).

Sidebar (`layouts/admin.html.erb`) ganha o item entre "Clientes" e o rodapé:

```erb
<li><%= link_to "Prospecção", admin_prospects_path, "aria-current": ("page" if controller_name == "prospects") %></li>
```

Rodar — VERDE.

---

### Task 5: cadastrar prospect como cliente (pré-preenchimento)

**Files:**
- Modify: `app/controllers/admin/clients_controller.rb`, `app/views/admin/prospects/index.html.erb`
- Test: `test/integration/admin_clients_test.rb`

**Interfaces:**
- Consumes: rota `new_admin_client_path` com `?client[...]`.

- [ ] **Step 11: RED — `new` aceita valores de pré-preenchimento**

`test/integration/admin_clients_test.rb`: `GET new_admin_client_path(client: { name: "Padaria X", address: "Rua Y, 10", phone: "(11) 99999-0000", website: "https://ex.com", google_place_id: "ChIJabc" })` → 200 e o HTML traz `value="Padaria X"` e `value="ChIJabc"` (campo hidden). FALHA — `new` ignora params hoje.

- [ ] **Step 12: GREEN — prefill no controller e link na tela**

```ruby
def new
  # Pré-preenchimento vindo da tela de prospecção: nada é salvo aqui, o admin
  # ainda confere e digita o email (que o Places não fornece) antes de submeter.
  @client = Client.new(params[:client] ? client_params : {})
end
```

`client_params` passa a permitir `:address, :phone, :website, :google_place_id`. Na view de prospecção, o botão vira:

```erb
<%= link_to "Cadastrar como cliente",
      new_admin_client_path(client: { name: r[:name], address: r[:address],
                                      phone: r[:phone], website: r[:website],
                                      google_place_id: r[:place_id] }),
      role: "button" %>
```

Rodar — VERDE.

---

### Task 6: fechamento

- [ ] **Step 13:** `bin/rails test` completo verde na worktree. Anotar contador (`Testes: X/X passando.`).
- [ ] **Step 14:** `bin/rubocop` sem ofensas. Anotar (`Lint: 0 ofensas.`).
- [ ] **Step 15:** `/ponytail-review` no diff. Atenção especial a: `dotenv-rails` (gem nova — justificar contra credentials), tabela `place_search_logs` (justificar contra contador em cache), e o objeto `PlaceSearch` (justificar por que não é código solto no controller). Resolver ou justificar cada achado.
- [ ] **Step 16:** Documentar no Notion, dois níveis: entrada em "Progresso do projeto" e tópico detalhado na página da tarefa 📍 (que passa a ser o registro de progresso desta entrega). Atualizar o `Status` da tarefa para "Concluído" e registrar em "Decisões já tomadas": escolha do `dotenv-rails` sobre credentials, `searchText` sobre `searchNearby`, cache de 12h como freio de custo, e não-persistência de dado do Places.
- [ ] **Step 17:** Commit local `feat: aba de prospecção de clientes via Google Places API`. Não fazer push nem merge.

## Fora de escopo (deliberado)

- **Fotos do Places** — exigem uma segunda requisição paga por foto.
- **`searchNearby` com raio/mapa** — precisa de coordenadas; entra se "buscar ao redor deste ponto" virar necessidade real.
- **Salvar prospect no banco antes de virar `Client`** — seria cache proibido de conteúdo do Places, e uma tabela a mais sem funil de vendas que a justifique. Enquanto não existir status de lead, prospect não cadastrado simplesmente não existe no banco.
- **Paginação dos resultados** — `pageSize: 20` numa tela só; `nextPageToken` custa outra requisição por página.
