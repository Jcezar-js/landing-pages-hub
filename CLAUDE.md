# Projeto: Monolito Rails para LPs Multi-cliente

Fonte de verdade: Notion (projeto + páginas de fase). Este arquivo é resumo pra contexto local.

## Motivação
Dois objetivos em paralelo: (1) aprender a programar de verdade usando IA como guia — entender o código, não só copiar sugestão pronta; (2) construir produto real: ferramenta pra vender landing pages a clientes locais.

Usuário é **iniciante total em programação**. Explicar conceitos, não só entregar código pronto.

## O que o produto faz
App Rails monolítico. Cada cliente é um registro (`Client`/`LandingPage`), conteúdo (textos, fotos, seções) em tabelas relacionadas. Template/HTML/CSS compartilhado entre clientes — o que muda por cliente é *dado*, não *código* (data-driven content / mini-CMS).

- URL por cliente: path `/lp/:slug` (não subdomínio — decisão tomada, subdomínio/domínio próprio descartados por ora)
- Devise pra login do admin (painel único — sem login/cadastro por cliente)
- 2 tipos de LP: **Loja** (endereço, horário, serviços, WhatsApp, mapa) e **Pessoal** (portfólio/currículo)
- Active Storage pra fotos

## Stack
Ruby on Rails 8 (via mise, não rbenv) + PostgreSQL + Devise + Active Storage + ERB.

## Fases (Notion)
0. Ambiente — ✅ concluído (mise, não rbenv)
1. Fundamentos de Ruby — ✅ concluído
2. Fundamentos de Rails com app-brinquedo (`blog_app` descartável, scaffold de `Post`) — ✅ concluído
3. Modelagem do domínio real — `Client` (`has_one :landing_page`) → `LandingPage` (`client:references slug:string:uniq template:string`, `has_many :sections`) → `Section` (`landing_page:references title:string content:text position:integer`, `has_many :photos`) → `Photo` (`section:references file_description:string position:integer`). Campo `template` guarda `"loja"` ou `"pessoal"` — decide quais seções/campos aparecem nas Fases 5 e 7, sem tabela separada por tipo. `dependent: :destroy` em cascata; `slug` único também via índice de banco (não só validação Rails, por causa de race condition)
4. Autenticação do admin — Devise no model `Admin` (só você, sem tela pública de cadastro); `before_action :authenticate_admin!` no `ApplicationController`, exceto na rota pública `/lp/:slug`. Sem multi-tenant: `Client` não loga, admin acessa qualquer `LandingPage` por id sem risco de IDOR (não existe "outro usuário" pra vazar dado)
5. Roteamento e template compartilhado — rota pública `get "/lp/:slug", to: "landing_pages#show"` (sem auth); `find_by!(slug:)`; view única que branch por `@landing_page.template` (loja vs pessoal) pra mostrar blocos específicos
6. Upload de imagens (Active Storage) — a detalhar: `has_one_attached`/`has_many_attached` em `Photo`, form de upload, variantes, validação de tipo/tamanho
7. Painel admin (nested attributes) — a detalhar: CRUD de `Client`s e `LandingPage`s pra você, `form_with`, edição de sections/photos juntas, reordenação via `position`
8. Deploy — a detalhar: hospedagem, env vars/segredos, banco em produção, storage de imagens (provável S3)

Página-mãe: https://app.notion.com/p/3b20f74b846e81ebb583f69fbc9ebf5d

## Estado atual do diretório
Raiz tem só `Gemfile` (`gem 'irb'`, resquício da Fase 1) — sem app Rails ainda. Fase 2 pede `rails new blog_app` num subdiretório à parte, descartável, não é o projeto final.

## Convenções de trabalho
- Toda decisão registrada no Notion (tabela "Decisões já tomadas" + notas de progresso por fase).
- Preferir doc oficial (guides.rubyonrails.org) a workaround improvisado quando travar em setup.
- **Antes de editar/gerar código: explicar a mudança e o porquê primeiro, depois aplicar.** Usuário iniciante — não editar direto sem contexto, nem só depois do fato.
