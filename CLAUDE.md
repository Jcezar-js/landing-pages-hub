# Projeto: Monolito Rails para LPs Multi-cliente

Fonte de verdade: Notion (projeto + páginas de fase). Este arquivo é resumo pra contexto local.

## Notion — mapa de páginas (não buscar, usar direto)

| Página | Link |
|---|---|
| Projeto (Visão geral + tabela "Decisões já tomadas", mesma página, seção `# Decisões já tomadas`) | https://app.notion.com/p/3bc0f74b846e8000a362d658afb8ec9a |
| Progresso do projeto (log geral, mais recente primeiro, 1 entrada resumida por commit) | https://app.notion.com/p/3bd0f74b846e810394dbf7b619436c0e |
| Banco "Tarefas" (as 9 fases, propriedades `Fase`/`Status`) | https://app.notion.com/p/75d3ef67c5284422b17afb69d5b3ba6a |
| Fase 0 — Ambiente | https://app.notion.com/3bc0f74b846e81c690abfa1ad8cbbbbb |
| Fase 1 — Fundamentos de Ruby | https://app.notion.com/3bc0f74b846e81a19bc2ceb0f00eae7b |
| Fase 2 — Fundamentos de Rails | https://app.notion.com/3bc0f74b846e8133a04ef5f4ae7483bb |
| Fase 3 — Modelagem do domínio | https://app.notion.com/3bc0f74b846e81e184d3e91627eceedc |
| Fase 4 — Autenticação do admin | https://app.notion.com/3bc0f74b846e8125b546e09dfb90f10f |
| Fase 5 — Roteamento e template (progresso: https://app.notion.com/p/3bd0f74b846e819bbab5f837f3cac8f7) | https://app.notion.com/3bc0f74b846e81ffa6e9f863de7e57b3 |
| Fase 6 — Upload de imagens | https://app.notion.com/3bc0f74b846e81b5b40ad46b2cc49886 |
| Fase 7 — Painel admin | https://app.notion.com/3bc0f74b846e810c8270c218ce5b9ed2 |
| Fase 8 — Deploy | https://app.notion.com/3bc0f74b846e81f5afcdcf149bd609d8 |

Cada página de fase ganha, ao começar a fase, subpágina filha `📓 Progresso — Fase N` (link some dentro da própria página da fase até ser criada) — usar mesmo padrão de nome pras fases 6-8 quando começarem.

## Escopo — painel admin como centro (decisão 2026-08-15)

Ideia de base continua a mesma: blocos reaproveitáveis, template compartilhado entre clientes, dado por cliente (não código). A partir de agora, **painel admin é o centro da aplicação** — é ele que vai controlar tudo (clients, landing pages, sections, photos).

**Ordem de execução revisada:**
1. Fase 5 (rota pública `/lp/:slug`) — em andamento na worktree `fase5-lp-publica`, teste RED já escrito (`test/integration/landing_pages_test.rb`), plano em `docs/superpowers/plans/2026-08-14-fase5-rota-publica-lp.md`. **Terminar antes de começar o resto.**
2. Fase 7 (painel admin — CRUD de Client/LandingPage/Section) — próxima depois da Fase 5, antes da Fase 6. `Photo` fica só com campo de descrição por enquanto (sem attach).
3. Fase 6 (upload de imagens, Active Storage) — depois do CRUD admin básico funcionar.
4. Fase 8 (deploy) — inalterada, por último.

## Convenções de trabalho
- Metodologia TDD continua: escrever cenário de teste (RED) antes do código, ver falhar, só então implementar (GREEN), depois refactor se precisar.
- Estrutura de diretórios segue convenção MVC padrão do Rails — sem camada de service extra por enquanto (decisão: manter simples até ter necessidade concreta).
- Toda decisão registrada no Notion (tabela "Decisões já tomadas" + notas de progresso por fase).
- Preferir doc oficial (guides.rubyonrails.org) a workaround improvisado quando travar em setup.
- **Toda mudança de código é documentada no Notion**, em dois níveis (não só resultado final, passo a passo da resolução):
  1. **Log geral** ("Progresso do projeto"): 1 entrada por commit, mais recente no topo. Formato: `## YYYY-MM-DD — Fase N, commit local \`hash\`` + worktree usada (se houver) + resumo de 1-3 linhas + contadores (`Testes: X/X passando.` / `Lint: 0 ofensas.`) + link `[Registro de progresso — Fase N](...)` pro detalhe completo.
  2. **Registro de progresso da fase** (subpágina filha da página da fase, `📓 Progresso — Fase N`): 1 tópico por commit, título `## YYYY-MM-DD — tipo: resumo curto` (tipo = prefixo de commit: fix/feat/refactor...). Corpo do tópico, nesta ordem:
     - **Status** — commit local / worktree (nome) / mergeado ou não na main.
     - **O problema** — sintoma observado + causa raiz. Analogia curta quando ajudar a fixar o conceito (opcional, usar quando fizer sentido).
     - **A correção** — o que mudou, com bloco de código do trecho relevante (arquivo comentado no topo do bloco).
     - **Testes de regressão adicionados** — lista numerada, o que cada teste cobre (principalmente o cenário que pegaria o bug antes de existir).
     - **Checklist de commit** (seguido antes de commitar) — testes, lint, documentação, commit, cada item marcado ✅.
     - **Lição pra próxima vez** — generalização do padrão, pra não repetir a causa raiz em outro lugar do código.
  Notas objetivas e diretas ao ponto, sem enrolação.
- **Nunca commitar ou mergear direto na main.** Fazer commit local e deixar pronto para push — o push/merge é decisão do usuário. Anotar a revisão das modificações no Notion.
- **Checklist obrigatório antes de qualquer commit, nesta ordem:**
  1. Testes passando, lint limpo, sem erros de compilação — código funcional.
  2. Rodar skill `/ponytail-review` no diff — resolver ou justificar cada achado antes de seguir.
  3. Documentação de progresso (skills padrão do Claude Code + progresso do projeto no Notion).
  4. Commit local.
- **Questionar abordagem antes de implementar.** Toda ideia/abordagem que o usuário propuser deve ser analisada em busca de problema grande no futuro (dívida técnica séria, risco de segurança, escalabilidade) ou problema de manutenção/suporte. Se achar problema, apresentar antes de implementar. A proposta de solução deve **adaptar** a ideia original a um formato mais realista, sem descartá-la nem reformulá-la por completo — manter a essência do que o usuário pediu.
