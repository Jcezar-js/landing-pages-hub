# Biblioteca de blocos: arquitetura de conteúdo por cliente

Data: 2026-08-14
Status: aprovado, aguardando plano de implementação

## Contexto

O desenho original (Fase 3) modelava conteúdo como `Section` com `title`/`content`
livres, e `LandingPage.template` (`"loja"` ou `"pessoal"`) decidindo, via branch na
view, quais seções apareciam. Ao planejar a Fase 5 (roteamento/renderização),
ficou claro que 2 categorias fixas não cobrem a variedade real de negócios
locais — sempre vai faltar caixa pra encaixar um cliente.

A alternativa cogitada primeiro — cada cliente com site bespoke, código próprio
gerado por IA, possivelmente em arquitetura de microsserviços — foi descartada:
não escala em auditoria/manutenção. Bug ou ajuste de design teria que ser
replicado manualmente em N sites diferentes, e microsserviços reintroduz a
complexidade de infra (DNS/certificado por cliente) já descartada no início do
projeto, sem ganho real no volume atual (poucos clientes locais).

## Decisão

Biblioteca de blocos reutilizáveis + composição — o mesmo princípio por trás de
page builders (Webflow, Elementor): um conjunto fechado de blocos versionados no
código; o site de cada cliente é a escolha de quais blocos usar, em que ordem,
com que dado. Novo bloco é raro e deliberado, não por-cliente.

Fica dentro do monolito Rails existente — nenhuma mudança de fronteira de
processo/deploy, só de modelagem de conteúdo.

## Modelo de dados

`Section` (já existe, Fase 3) muda:

- `component_type:string` — novo. Restrito a `Section::COMPONENT_TYPES`
  (lista fechada, validada com `inclusion:`). Ex.: `hero`, `servicos`,
  `depoimentos`, `contato_whatsapp`, `mapa`, `sobre_mim`, `experiencia`.
- `data:jsonb` — substitui `content:text`. Cada bloco lê as chaves que
  precisa (`section.data["telefone"]`, `section.data["itens"]`).
- `title`, `position` — mantidos como estão.

`LandingPage.template` (`"loja"`/`"pessoal"`) é removido. Nenhuma lógica no
novo desenho lê esse campo — qualquer cliente usa qualquer combinação de
blocos.

`Client` ganha campos de CRM (status do lead/projeto) — o admin passa a
funcionar também como CRM, não só editor de conteúdo.

`Photo` não muda — continua `belongs_to :section`, cabe em blocos como
`galeria` (Active Storage entra na Fase 6, sem mudança de plano aqui).

## Renderização

Uma partial por tipo de bloco em `app/views/sections/`:

```
app/views/sections/_hero.html.erb
app/views/sections/_servicos.html.erb
app/views/sections/_depoimentos.html.erb
app/views/sections/_contato_whatsapp.html.erb
app/views/sections/_mapa.html.erb
app/views/sections/_sobre_mim.html.erb
```

`landing_pages/show.html.erb`:

```erb
<% @landing_page.sections.each do |section| %>
  <%= render "sections/#{section.component_type}", section: section %>
<% end %>
```

Sem gem nova — `render partial:` já resolve a composição. Se as partials
ficarem grandes/repetitivas demais no futuro, upgrade natural é a gem
`view_component` (padrão do ecossistema Rails pra isso) — não necessário
agora (YAGNI).

## Fluxo de onboarding

Dois caminhos, deliberadamente separados:

1. **Cliente novo, blocos já existem** — CRUD puro pelo admin (Fase 7): cria
   `Client`, cria `LandingPage` (slug), adiciona `Section`s escolhendo
   `component_type` e preenchendo `data`, ordena por `position`. Nenhuma IA
   envolvida.
2. **Bloco novo precisa existir** — skill dedicada (`/new-block`, a definir)
   scaffolda: adiciona o tipo em `COMPONENT_TYPES`, cria a partial com
   estrutura inicial e documenta as chaves de `data` esperadas. Fica na
   biblioteca permanentemente.

Essa fronteira é o ponto central do desenho: onboarding normal nunca gera
código, só dado.

## Observabilidade

"Quem usa o bloco X" não precisa de infra de tracking — é dado que já existe
no modelo:

```ruby
Section.where(component_type: "mapa").includes(landing_page: :client).map(&:client)
```

Útil pra saber quem avisar/quem foi afetado se um bloco precisar de correção.
Detecção de erro em produção (ex. Sentry) é aditivo, fora de escopo deste
spec.

## Testes

- Model: `Section` valida `component_type` contra `COMPONENT_TYPES`.
- Integração "smoke": para cada tipo em `COMPONENT_TYPES`, cria uma `Section`
  mínima válida e renderiza `/lp/:slug` esperando 200 — pega bloco cadastrado
  sem partial correspondente (typo de nome etc.) antes de produção.

## Erro/validação — fora de escopo por ora

Validação campo-a-campo do `data` esperado por tipo de bloco (ex.: `mapa`
exige `endereco`) fica de fora da primeira versão — só entra se isso virar
problema real (YAGNI). Falta de chave em `data` hoje estoura erro de ERB,
pego pelo teste smoke antes de produção.

## Impacto no roadmap (Notion)

Fases 0, 1, 2, 4 intactas. Fase 3 precisa de migration (`component_type`,
`data:jsonb`, drop `template`). Fase 5 muda de "branch loja/pessoal" pra
"render partial por `component_type`". Fase 7 (painel) ganha CRM em `Client`
e passa a editar blocos (escolher tipo, preencher dado), como já era o
objetivo original — sem mudança de escopo, só de mecanismo.

## Fora de escopo

- Rails Engines / isolamento por cliente (só se um cliente algum dia
  precisar de model/dado próprio — não é o caso hoje).
- Deploy/domínio por cliente (microsserviços) — decisão já revisitada e
  descartada nesta rodada.
- Gem `view_component` — upgrade futuro se `render partial:` não bastar.
