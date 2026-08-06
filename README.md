```
  _     ____    _   _ _   _ ____
 | |   |  _ \  | | | | | | | __ )
 | |   | |_) | | |_| | | | |  _ \
 | |___|  __/  |  _  | |_| | |_) |
 |_____|_|     |_| |_|\___/|____/

        landing pages, um template, N clientes
```

> Monolito Rails que serve landing pages pra vários clientes a partir do
> mesmo template — o que muda por cliente é **dado**, não código.

## O que é isso

Pequenos negócios locais precisam de uma landing page profissional, mas
sem pagar o preço de um freelancer a cada ajuste de texto ou foto. Esse
projeto ataca esse meio-termo: uma base de LP com qualidade visual
consistente, onde atender um novo cliente é barato porque o template é
compartilhado.

## Regra de negócio

Cada cliente é um registro no banco (`Client` → `LandingPage` → `Section`
→ `Photo`). Um único template compartilhado renderiza qualquer cliente,
injetando os dados certos — o que muda por cliente é dado, não código
(mini-CMS).

```
┌───────────┐     ┌──────────────┐     ┌───────────┐     ┌───────────┐
│  Client   │─1:1▶│ LandingPage  │─1:N▶│  Section  │─1:N▶│   Photo   │
└───────────┘     └──────────────┘     └───────────┘     └───────────┘
                     slug (único)         position           position
                     template:
                     loja | pessoal
```

* Cada `Client` tem no máximo uma `LandingPage`, identificada por `slug`
  único, acessada em `/lp/:slug` (sem subdomínio nem domínio próprio).
* `template` define o tipo — `loja` (endereço, horário, serviços,
  WhatsApp, mapa) ou `pessoal` (portfólio/currículo) — decide quais
  seções aparecem, sem tabela separada por tipo.
* Existe só **1 admin** (você), que gerencia todos os clientes pelo
  painel. Cliente não loga, não tem conta.
* Apagar um `Client` apaga em cascata `LandingPage`, `Section`s e
  `Photo`s (`dependent: :destroy`).

## Stack

* Ruby on Rails 8 (via `mise`, não `rbenv`)
* PostgreSQL
* Devise — autenticação do admin
* Active Storage — fotos por cliente
* ERB + template compartilhado

## Metodologia

TDD (red → green → refactor): o teste é escrito antes do código, roda e
falha por um motivo esperado, só depois vem a implementação mínima pra
passar. Testes com Minitest.

## Instalação e uso

```bash
git clone git@github.com:Jcezar-js/landing-pages-hub.git
cd landing-pages-hub
bin/setup          # instala gems e prepara o banco (Postgres precisa estar rodando)
bin/rails server    # sobe em http://localhost:3000
bin/rails test      # roda a suíte de testes
```
