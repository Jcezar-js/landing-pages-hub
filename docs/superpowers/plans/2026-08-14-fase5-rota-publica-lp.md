# Fase 5 — Rota Pública da Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Visitante acessa `/lp/:slug` sem login e vê a landing page do cliente, com bloco de conteúdo diferente conforme `template` ("loja" ou "pessoal"). Slug inexistente retorna 404.

**Architecture:** Uma rota pública (`get "/lp/:slug"`) aponta pra `LandingPagesController#show`, que pula a autenticação Devise só nessa action. A view é única e decide o que renderizar (partial `_loja` ou `_pessoal`) olhando `@landing_page.template` — o dado muda, o código não.

**Tech Stack:** Rails 8, Devise, Minitest (`ActionDispatch::IntegrationTest`), fixtures.

**Spec:** `CLAUDE.md` (raiz do repo), seção "Fases (Notion)" → item 5.

## Global Constraints

- Rota pública é path `/lp/:slug`, não subdomínio.
- Sem multi-tenant / sem login de cliente — só o admin loga (Devise, model `Admin`).
- `ApplicationController` tem `before_action :authenticate_admin!` — qualquer controller novo herda isso e precisa pular explicitamente pra rota pública.

---

### Task 1: Rota pública + controller + view com branch por template

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/landing_pages_controller.rb`
- Create: `app/views/landing_pages/show.html.erb`
- Create: `app/views/landing_pages/_loja.html.erb`
- Create: `app/views/landing_pages/_pessoal.html.erb`
- Test: `test/integration/landing_pages_test.rb` (já existe no diretório, sem tracking no git — usar como está)

**Interfaces:**
- Consumes: `LandingPage#slug`, `LandingPage#template` (`"loja"`/`"pessoal"`), `LandingPage#client` → `Client#name`, `LandingPage#sections` (ordenado por `position`), `Section#title`, `Section#content` — todos já existem em `app/models/`.
- Produces: rota nomeada implícita `landing_page_path(slug)` (via `get "/lp/:slug"`), action `LandingPagesController#show` que seta `@landing_page`.

- [ ] **Step 1: Rodar o teste existente pra confirmar que falha (rota não existe)**

Run: `bin/rails test test/integration/landing_pages_test.rb`
Expected: FAIL — `ActionController::UrlGenerationError` ou "No route matches" pro GET `/lp/loja-um`.

- [ ] **Step 2: Adicionar a rota pública**

Em `config/routes.rb`, adicionar antes do `namespace :admin`:

```ruby
Rails.application.routes.draw do
  devise_for :admins

  get "/lp/:slug", to: "landing_pages#show", as: :landing_page

  namespace :admin do
    root to: "dashboard#index"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
```

- [ ] **Step 3: Rodar o teste de novo — deve falhar em outro ponto (controller não existe)**

Run: `bin/rails test test/integration/landing_pages_test.rb`
Expected: FAIL — `uninitialized constant LandingPagesController`.

- [ ] **Step 4: Criar o controller, pulando a autenticação Devise nessa action**

Criar `app/controllers/landing_pages_controller.rb`:

```ruby
class LandingPagesController < ApplicationController
  skip_before_action :authenticate_admin!, only: :show

  def show
    @landing_page = LandingPage.find_by!(slug: params[:slug])
  end
end
```

`find_by!` levanta `ActiveRecord::RecordNotFound` quando o slug não existe; em `test`/`production` o Rails converte isso em 404 automaticamente (`config.action_dispatch.show_exceptions` já está configurado em `config/environments/test.rb`), então não precisa de `rescue_from` manual.

- [ ] **Step 5: Rodar o teste de novo — o caso de sucesso deve falhar por falta de view, o 404 já deve passar**

Run: `bin/rails test test/integration/landing_pages_test.rb`
Expected: teste "unknown slug returns 404" PASS; teste "visitor can view landing page without logging in" FAIL com `ActionView::MissingTemplate`.

- [ ] **Step 6: Criar a view que branch por template**

Criar `app/views/landing_pages/show.html.erb`:

```erb
<h1><%= @landing_page.client.name %></h1>

<% if @landing_page.template == "loja" %>
  <%= render "loja" %>
<% else %>
  <%= render "pessoal" %>
<% end %>
```

Criar `app/views/landing_pages/_loja.html.erb`:

```erb
<div class="landing-page landing-page--loja">
  <% @landing_page.sections.each do |section| %>
    <section>
      <h2><%= section.title %></h2>
      <p><%= section.content %></p>
    </section>
  <% end %>
</div>
```

Criar `app/views/landing_pages/_pessoal.html.erb`:

```erb
<div class="landing-page landing-page--pessoal">
  <% @landing_page.sections.each do |section| %>
    <article>
      <h2><%= section.title %></h2>
      <p><%= section.content %></p>
    </article>
  <% end %>
</div>
```

- [ ] **Step 7: Rodar o teste completo — os dois casos devem passar**

Run: `bin/rails test test/integration/landing_pages_test.rb`
Expected: PASS (2 runs, 0 failures, 0 errors).

- [ ] **Step 8: Rodar a suíte inteira pra garantir que nada mais quebrou**

Run: `bin/rails test`
Expected: PASS (nenhuma falha nova; auth do admin — Fase 4 — continua passando).

- [ ] **Step 9: Commit**

```bash
git add config/routes.rb app/controllers/landing_pages_controller.rb app/views/landing_pages/ test/integration/landing_pages_test.rb
git commit -m "feat: rota pública /lp/:slug com view por template (Fase 5)"
```
