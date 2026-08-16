# Fase 7 — Painel admin (CRUD) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:subagent-driven-development (recomendado) ou superpowers:executing-plans para implementar este plano task a task. Passos usam checkbox (`- [ ]`) pra tracking.

## Context

O painel admin (Devise, já autenticado desde a Fase 4) hoje só tem uma tela vazia (`Admin::DashboardController#index`). O modelo de dados (`Client` → `LandingPage` → `Section`, com `Section` usando `component_type` fechado + `data:jsonb` da biblioteca de blocos) já existe ou está prestes a existir (worktree `fase5-lp-publica`, ainda não mergeada), mas nada no admin consegue criar ou editar esses registros — hoje só dá pra popular via console/seed. A decisão registrada no Notion em 2026-08-15 ("painel admin como centro da aplicação") torna esse CRUD o próximo passo obrigatório: sem ele, onboardar um cliente novo não é possível pelo produto. Este plano cobre exatamente esse CRUD (Client + LandingPage + Section), deixando `Photo` de fora (aguarda Active Storage na Fase 6).

Duas decisões foram fechadas com o usuário antes deste plano:
- **Sem campo de CRM/status em `Client` nesta fase** — o Notion deixava isso em aberto ("valores a definir quando a fase começar"); ficou definido que o CRUD de `Client` fica só com `name`/`email`, e o status de lead entra em fase futura quando o funil real existir.
- **2 controllers**, não 1: `Admin::ClientsController` isolado + `Admin::LandingPagesController` aninhado, com nested attributes só entre `LandingPage`→`Section`. Evita form triplo-aninhado (Client+LandingPage+Sections numa tela só), que juntaria 3 validações num único ciclo de erro e complicaria tanto o form quanto os testes.

**Pré-requisito, não é uma task deste plano:** a worktree `fase5-lp-publica` precisa estar mergeada na main antes de começar (schema com `Section.component_type`/`data:jsonb`, sem `LandingPage.template`). O primeiro step da Task 2 confere isso.

## Architecture

Dois controllers namespaced em `admin`. `Admin::ClientsController` é um CRUD isolado e convencional de `Client` (`name`, `email`). `Admin::LandingPagesController` é aninhado sob `/admin/clients/:client_id/landing_page` (recurso **singular** — `Client has_one :landing_page`) e gerencia `LandingPage` (`slug`) + suas `Section`s num único formulário via `accepts_nested_attributes_for :sections` (`allow_destroy: true`, `reject_if: :all_blank`) no model `LandingPage`. O campo `data` (jsonb) é editado como texto JSON cru num `text_area`; um setter customizado em `Section#data=` converte a string em `Hash` na atribuição e valida JSON malformado. Sem JS extra: "adicionar bloco" é resolvido com um número fixo de slots em branco pré-renderizados (`sections.build` × N) em vez de campo dinâmico via JS/Stimulus/Cocoon.

## Tech Stack

Rails 8, Devise (já configurado, reaproveitado sem mudança), Minitest (`ActionDispatch::IntegrationTest` + `ActiveSupport::TestCase`, mesmo padrão já usado no projeto — sem Capybara/system tests), fixtures, PostgreSQL (jsonb nativo). Nenhuma gem nova.

## Spec

`CLAUDE.md` (raiz do repo), seção "Escopo — painel admin como centro". Notion, Fase 7 — Painel admin: https://app.notion.com/3bc0f74b846e810c8270c218ce5b9ed2. Decisões já tomadas (Projeto, seção "Decisões já tomadas"): https://app.notion.com/p/3bc0f74b846e8000a362d658afb8ec9a

## Global Constraints

- TDD estrito: RED → GREEN → refactor em cada step, sem pular a etapa de ver o teste falhar antes de implementar.
- `ApplicationController` já tem `before_action :authenticate_admin!` (herdado por qualquer controller novo) — **não** duplicar teste de "visitante é redirecionado" em cada controller novo; já coberto globalmente por `test/integration/admin_authentication_test.rb` (Fase 4).
- `Client` fica só com `name`/`email` nesta fase — sem enum de CRM/status.
- `Photo` fora de escopo — nenhuma view/controller toca em `Photo` aqui.
- 2 controllers, não 3, conforme decidido acima.
- Nunca commitar/mergear direto na `main`. Trabalhar numa worktree dedicada, mesmo padrão da Fase 5:
  ```bash
  git worktree add .claude/worktrees/fase7-painel-admin -b fase7-painel-admin
  ```
  Todos os comandos `bin/rails test` / commits deste plano rodam dentro dessa worktree.
- Checklist obrigatório antes de cada commit (CLAUDE.md): (1) testes passando + `bin/rubocop` limpo; (2) rodar `/ponytail-review` no diff e resolver/justificar achados; (3) documentar progresso no Notion (log geral + `📓 Progresso — Fase 7`); (4) só então commitar local.

---

### Task 1: Rotas `/admin/clients` + `Admin::ClientsController` CRUD completo

**Files:**
- Modify: `config/routes.rb`
- Modify: `app/models/client.rb`
- Create: `app/controllers/admin/clients_controller.rb`
- Create: `app/views/admin/clients/index.html.erb`, `new.html.erb`, `edit.html.erb`, `_form.html.erb`
- Test: `test/models/client_test.rb`, `test/integration/admin_clients_test.rb`

**Interfaces:**
- Consumes: `Client#name`, `Client#email` (já existem); `Devise::Test::IntegrationHelpers#sign_in` (já configurado em `test_helper.rb`).
- Produces: rotas `admin_clients_path`, `new_admin_client_path`, `edit_admin_client_path(client)`, `admin_client_path(client)`; `Admin::ClientsController` com `index/new/create/edit/update/destroy`.

- [ ] **Step 1: RED — teste de validação de `name` no model**

`test/models/client_test.rb`:
```ruby
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
```
Run: `bin/rails test test/models/client_test.rb`
Expected: FAIL — sem validação ainda, `assert_not client.valid?` falha.

- [ ] **Step 2: GREEN — validação em `app/models/client.rb`**
```ruby
class Client < ApplicationRecord
  has_one :landing_page, dependent: :destroy
  validates :name, presence: true
end
```
Run: `bin/rails test test/models/client_test.rb` → Expected: PASS.

- [ ] **Step 3: RED — teste de integração do CRUD completo**

`test/integration/admin_clients_test.rb` (index/new/create válido+inválido/edit/update válido+inválido/destroy, usando `sign_in admins(:one)` no `setup`, `assert_redirected_to`/`assert_response :unprocessable_entity` conforme padrão Rails).
Run: Expected: FAIL — `NoMethodError: undefined method 'admin_clients_path'`.

- [ ] **Step 4: Rota** — `resources :clients, only: %i[index new create edit update destroy]` dentro de `namespace :admin`.
Run: Expected: FAIL — `uninitialized constant Admin::ClientsController`.

- [ ] **Step 5: Controller** (`app/controllers/admin/clients_controller.rb`) — `index/new/create/edit/update/destroy` padrão Rails, `client_params` permitindo `:name, :email`, `render ..., status: :unprocessable_entity` nos casos inválidos, redirect pra `edit_admin_client_path` após create/update.
Run: Expected: FAIL — `ActionView::MissingTemplate`.

- [ ] **Step 6: Views** — `_form`, `new`, `edit`, `index` (tabela simples com nome/email/link editar/botão remover).
Run: Expected: PASS.

- [ ] **Step 7:** `bin/rails test` completo → PASS, sem regressão.
- [ ] **Step 8:** `bin/rubocop app/controllers/admin/clients_controller.rb app/models/client.rb` → limpo.
- [ ] **Step 9: Commit** — `feat: CRUD de Client no painel admin (Fase 7)`.

---

### Task 2: Model — `accepts_nested_attributes_for :sections` + `Section#data=` (JSON via texto) + fixtures

**Files:**
- Modify: `app/models/landing_page.rb`, `app/models/section.rb`
- Modify (se necessário): `test/fixtures/landing_pages.yml`, `test/fixtures/sections.yml`
- Test: `test/models/landing_page_test.rb`, `test/models/section_test.rb`

**Interfaces:**
- Consumes: `LandingPage#sections`, `Section::COMPONENT_TYPES`, `Section#data` (jsonb, pós-merge Fase 5).
- Produces: `LandingPage#sections_attributes=`; `Section#data=` aceitando `String` JSON além de `Hash`, com erro de validação em `data` quando o JSON é inválido.

- [ ] **Step 1: Confirmar baseline do schema pós-Fase 5**
Run: `bin/rails test`. Se fixtures ainda estiverem no formato antigo (`template:`, `content:`), atualizar `landing_pages.yml`/`sections.yml` pro formato pós-blocos (`slug` sem `template`; `component_type`/`data`/`position` em vez de `content`) antes de prosseguir. `clients.yml` não muda.

- [ ] **Step 2: RED — nested attributes em `LandingPage`**
`test/models/landing_page_test.rb`: 3 testes — cria section via `sections_attributes`, rejeita linha em branco (`reject_if: :all_blank`), remove via `_destroy: "1"` (`allow_destroy`).
Run: Expected: FAIL — `NoMethodError: undefined method 'sections_attributes='`.

- [ ] **Step 3: GREEN**
```ruby
class LandingPage < ApplicationRecord
  belongs_to :client
  has_many :sections, -> { order(:position) }, dependent: :destroy
  validates :slug, presence: true, uniqueness: true
  accepts_nested_attributes_for :sections, allow_destroy: true, reject_if: :all_blank
end
```
Run: Expected: PASS.

- [ ] **Step 4: RED — `Section#data=` aceitando string JSON**
`test/models/section_test.rb`: valida `component_type` (já existente na worktree, reconfirmar), `data` aceita string JSON e vira Hash, JSON malformado gera erro em `errors[:data]`, Hash direto continua funcionando.
Run: Expected: FAIL — round-trip padrão do jsonb devolve String, não Hash (`assert_equal` falha).

- [ ] **Step 5: GREEN — setter customizado**
```ruby
class Section < ApplicationRecord
  COMPONENT_TYPES = %w[hero servicos depoimentos contato_whatsapp mapa sobre_mim experiencia].freeze
  belongs_to :landing_page
  has_many :photos, -> { order(:position) }, dependent: :destroy
  validates :component_type, inclusion: { in: COMPONENT_TYPES }
  validate :data_must_be_valid_json

  def data=(value)
    if value.is_a?(String)
      @data_json_invalid = false
      begin
        value = value.strip.presence ? JSON.parse(value) : {}
      rescue JSON::ParserError
        @data_json_invalid = true
        value = {}
      end
    end
    super(value)
  end

  private

  def data_must_be_valid_json
    errors.add(:data, "precisa ser um JSON válido (ex.: {\"titulo\": \"texto\"})") if @data_json_invalid
  end
end
```
Run: Expected: PASS.

- [ ] **Step 6:** re-rodar `test/models/landing_page_test.rb` (setter não pode quebrar nested attributes) → PASS.
- [ ] **Step 7:** `bin/rails test` completo → PASS.
- [ ] **Step 8:** `bin/rubocop app/models/landing_page.rb app/models/section.rb` → limpo.
- [ ] **Step 9: Commit** — `feat: nested attributes de Section em LandingPage + data JSON via texto (Fase 7)`.

---

### Task 3: Rotas aninhadas + `Admin::LandingPagesController` + form nested de Sections

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/admin/landing_pages_controller.rb`
- Create: `app/views/admin/landing_pages/new.html.erb`, `edit.html.erb`, `_form.html.erb`
- Test: `test/integration/admin_landing_pages_test.rb`

**Interfaces:**
- Consumes: `Client#build_landing_page` (gerado pelo `has_one`), `LandingPage#sections_attributes=`, `Section::COMPONENT_TYPES`, `Section#data` (Task 2).
- Produces: rotas `new_admin_client_landing_page_path(client)`, `admin_client_landing_page_path(client)` (create/update/destroy), `edit_admin_client_landing_page_path(client)`; `Admin::LandingPagesController` com `new/create/edit/update/destroy`.

- [ ] **Step 1: RED — teste de integração completo**

`test/integration/admin_landing_pages_test.rb`: 8 testes — `new` em branco, `create` com nested sections válidas, `create` ignorando linha em branco, `create` com JSON inválido re-renderiza com erro, `edit` mostra sections existentes, `update` altera slug + edita section existente + adiciona nova, `update` com `_destroy` remove section, `destroy` remove a landing page inteira e cascade nas sections.
Run: Expected: FAIL — `NoMethodError: undefined method 'new_admin_client_landing_page_path'`.

- [ ] **Step 2: Rota aninhada singular**
```ruby
namespace :admin do
  root to: "dashboard#index"
  resources :clients, only: %i[index new create edit update destroy] do
    resource :landing_page, only: %i[new create edit update destroy]
  end
end
```
Run: Expected: FAIL — `uninitialized constant Admin::LandingPagesController`.

- [ ] **Step 3: Controller**
`app/controllers/admin/landing_pages_controller.rb` — `before_action :set_client` (sempre), `set_landing_page` (edit/update/destroy, via `@client.landing_page || raise(ActiveRecord::RecordNotFound)`); `new`/`edit` chamam `build_blank_sections` (`BLANK_SECTION_SLOTS = 3`, `sections.build` × N) pra pré-renderizar slots vazios no form; `create` via `@client.build_landing_page(landing_page_params)`; `landing_page_params` permite `:slug, sections_attributes: %i[id component_type title data position _destroy]`.
Run: Expected: FAIL — `ActionView::MissingTemplate` nos testes que renderizam form (create/update/destroy válidos já passam, só redirecionam).

- [ ] **Step 4: Views**
`_form.html.erb` — `form_with model: [:admin, @client, landing_page]`, campo `slug`, `f.fields_for :sections` com `select :component_type` (`Section::COMPONENT_TYPES`), `text_field :title`, `number_field :position`, `text_area :data` (valor `sf.object.data.to_json`), `check_box :_destroy` só pra records persistidos. `new.html.erb`/`edit.html.erb` renderizam a partial; `edit.html.erb` inclui `button_to "Remover landing page", ..., method: :delete`.
Run: Expected: PASS (8 runs).

- [ ] **Step 5:** `bin/rails test` completo → PASS, sem regressão em Fases 4/5/Task 1/2.
- [ ] **Step 6:** `bin/rubocop app/controllers/admin/landing_pages_controller.rb` → limpo.
- [ ] **Step 7:** rodar `/ponytail-review` no diff completo da fase (Tasks 1–3) — resolver ou justificar cada achado.
- [ ] **Step 8: Commit** — `feat: CRUD aninhado de LandingPage + Sections no painel admin (Fase 7)`.
- [ ] **Step 9: Documentação no Notion** — log geral ("Progresso do projeto", 1 entrada por commit) + subpágina `📓 Progresso — Fase 7` (1 tópico por commit, formato do CLAUDE.md: Status/O problema/A correção/Testes de regressão/Checklist/Lição pra próxima vez).

---

### Decisões de design embutidas (registrar no Notion junto com a fase)

- `Client` sem `show` — `edit` já serve como tela de detalhe.
- `LandingPage` sem `show` próprio — `new`/`edit` cobrem o ciclo; deletar é um botão dentro do `edit`.
- "Adicionar bloco" via 3 slots em branco fixos (`BLANK_SECTION_SLOTS`) em vez de JS dinâmico (Stimulus/Cocoon) — decisão explícita de não somar dependência nova; se 3 for pouco na prática, é só subir a constante, não precisa reabrir o desenho.
- `Section#data=` guarda flag de instância (`@data_json_invalid`) e valida via `validate :data_must_be_valid_json` — necessário porque `errors.add` direto no setter seria apagado pelo `errors.clear` no início do ciclo de validação; é o jeito correto de expor erro de JSON malformado sem perder o texto digitado.

---

### Task 4 — movida para tarefa própria (2026-08-15)

O autocomplete de `Client` via Google Places API saiu do escopo desta fase e virou tarefa separada no banco "Tarefas" do Notion: [Autocomplete de Client via Google Places API (New)](https://app.notion.com/p/3bd0f74b846e81eaa197c2c5e1981e5e). A Fase 7 fechou com o CRUD manual (Task 1–3, commit `fd3e514`); nada do Places foi implementado.

O conteúdo abaixo fica como registro histórico do desenho — a versão viva dos passos está na tarefa do Notion.

**Decisão 2026-08-15, revisada:** ideia original era substituir o cadastro de `Client` por busca+botão via Google Places. Análise levantou 2 problemas: (1) Places não devolve email, campo obrigatório aqui — não elimina digitação manual; (2) acoplar o cadastro a uma API externa paga só pra 2 campos é dependência desproporcional ao ganho. Adaptação: mantém o form manual (Task 1) como caminho principal; Places entra só como **autocomplete opcional** que pré-preenche campos, não como substituto do form. Entra depois do CRUD básico (Task 1–3) estar funcionando, não bloqueia esta fase.

**Custo/quota (verificado 2026-08-15):** Text Search (New), tier Pro — que devolve `displayName`/`formattedAddress`/`location`/telefone/site, os campos que interessam aqui — tem **5.000 chamadas grátis por mês** (SKU-based, substituiu o antigo crédito de $200 compartilhado). Uso solo de admin, 1 busca = 1 request, não chega perto de 1.000/mês. Sem risco de custo nesse volume. Fonte: [Places API — Usage and Billing](https://developers.google.com/maps/documentation/places/web-service/usage-and-billing).

**Schema — campos do `Place` (Text Search Pro) mapeados pra `Client`:**

| Campo Places (`Place` resource) | Tipo | Coluna nova em `Client` |
|---|---|---|
| `id` | string | `google_place_id:string` (nullable, unique quando presente) |
| `displayName.text` | string | usado só pra sugerir `name`, não persiste separado |
| `formattedAddress` | string | `address:string` (nullable) |
| `nationalPhoneNumber` | string | `phone:string` (nullable) |
| `websiteUri` | string | `website:string` (nullable) |
| `location.latitude`/`location.longitude` | number | fora de escopo por ora — sem uso concreto ainda (YAGNI); revisitar se um mapa no admin virar necessidade real |

`email` continua sem equivalente no Places — preenchimento manual obrigatório mesmo com autocomplete.

- [ ] **Step 1: RED — migration + validação**
`test/models/client_test.rb`: `google_place_id` é opcional e único quando presente (`allow_nil: true` na unicidade).
Run: Expected FAIL — colunas não existem.

- [ ] **Step 2: GREEN** — migration adicionando `google_place_id:string` (index único, `allow_nil`), `address:string`, `phone:string`, `website:string` em `clients`; validação de unicidade em `Client`.

- [ ] **Step 3: RED — endpoint de busca no admin**
`test/integration/admin_client_places_search_test.rb`: `GET /admin/clients/places_search?q=...` (autenticado) retorna JSON com `name`/`address`/`phone`/`website`/`place_id` por resultado. Stub da chamada HTTP externa (`WebMock`/`webmock` — **gem nova**, avaliar se já não dá pra usar `Net::HTTP` + stub manual antes de somar dependência).
Run: Expected FAIL — rota não existe.

- [ ] **Step 4: GREEN** — `Admin::ClientsController#places_search` (ou controller dedicado) chama Places API (New) `:searchText` via `Net::HTTP`/`Faraday` (avaliar se `Net::HTTP` da stdlib resolve antes de somar gem), key via `Rails.application.credentials`, timeout curto, trata erro de rede sem quebrar o form.

- [ ] **Step 5: Views** — campo de busca acima do form de novo `Client`; resultado lista nome+endereço; botão "usar este" preenche `name`/`address`/`phone`/`website`/`google_place_id` nos campos do form (sem submit automático — usuário confere e ainda digita `email` antes de salvar).

- [ ] **Step 6:** `bin/rails test` completo → PASS.
- [ ] **Step 7:** `bin/rubocop` limpo.
- [ ] **Step 8:** `/ponytail-review` no diff — atenção especial a: gem nova (WebMock) só se stub manual não bastar; client HTTP (Faraday vs `Net::HTTP` da stdlib).
- [ ] **Step 9: Commit** — `feat: autocomplete de Client via Google Places API (Fase 7, pós-CRUD)`.

---

## Verification

1. `bin/rails test` — suíte inteira verde (Fases 4, 5 e as 3 tasks desta fase), sem regressão.
2. `bin/rubocop` limpo no diff.
3. Manual smoke test via `bin/rails server`: logar como admin (`admins(:one)` / seed local), criar um `Client`, criar a `LandingPage` dele com 1–2 sections (JSON válido no campo `data`), conferir que `/lp/:slug` (rota pública da Fase 5) reflete o conteúdo salvo, editar e remover uma section, remover a landing page inteira, remover o client.
4. `/ponytail-review` no diff completo antes do commit final da Task 3.
