---
name: ciclo-dev
description: Ciclo de desenvolvimento deste projeto (monolito Rails de LPs multi-cliente), da escolha da tarefa no Notion até o commit local — worktree, plano, TDD, checklist obrigatório antes de commitar e documentação de progresso no Notion. Use quando for começar uma fase/tarefa, implementar qualquer mudança de código, ou quando o usuário disser "ciclo", "começar fase N", "vamos implementar X" ou pedir para commitar.
---

# Ciclo de desenvolvimento

Fonte de verdade das decisões é o Notion (mapa de páginas em `CLAUDE.md`). Esta skill é o procedimento; o conteúdo das fases está lá.

## 1. Abrir a tarefa

- Ler a página da fase no Notion + a seção `# Decisões já tomadas` da página do Projeto. Não buscar no workspace: os links estão em `CLAUDE.md`.
- Se a fase está começando agora e ainda não tem subpágina `📓 Progresso — Fase N`, criar (filha da página da fase) e linkar dentro da página da fase.
- **Questionar a abordagem antes de implementar.** Procurar dívida técnica séria, risco de segurança, problema de escala ou de manutenção. Achou problema: apresentar antes de escrever código, e propor uma versão *adaptada* da ideia do usuário — manter a essência, não descartar nem reformular por completo.

## 2. Worktree

Toda mudança de código sai da `main`. Worktree dedicada:

```bash
git worktree add .claude/worktrees/<nome> -b <branch>
```

Todos os `bin/rails test`, `bin/rubocop` e commits rodam dentro dela.

## 3. Plano (só quando a fase começa)

Fase nova ganha arquivo `docs/superpowers/plans/YYYY-MM-DD-fase<N>-<slug>.md`, mesmo formato dos planos das fases 5 e 7: Context, Architecture, Tech Stack, Spec, Global Constraints, e Tasks com steps em checkbox (`- [ ]`), cada step marcado RED ou GREEN.

Tarefa avulsa dentro de uma fase já aberta (fix, ajuste, complemento) não precisa de arquivo de plano — vai direto pro passo 4.

## 4. Implementar em TDD

Por step, sem pular etapa:

1. **RED** — escrever o teste e rodar até vê-lo falhar. Ver a falha é parte do passo.
2. **GREEN** — código mínimo que faz passar.
3. **Refactor** — só se precisar.

Convenções:
- Minitest (`ActionDispatch::IntegrationTest` / `ActiveSupport::TestCase`) + fixtures. Sem Capybara, sem system tests.
- MVC padrão do Rails. Sem camada de service enquanto não houver necessidade concreta.
- Todo trecho de implementação nossa (não gerado por scaffold/convenção) abre com comentário curto: `# --- início: lógica nossa (X) ---`.
- Travou em setup: consultar guides.rubyonrails.org antes de improvisar workaround.

## 5. Checklist obrigatório antes do commit

Nesta ordem, sem pular:

1. `bin/rails test` passando e `bin/rubocop` sem ofensas. Anotar os contadores (`Testes: X/X passando.` / `Lint: 0 ofensas.`).
2. Rodar `/ponytail-review` no diff. Resolver ou justificar **cada** achado antes de seguir.
3. Documentar no Notion, dois níveis (passo a passo da resolução, não só o resultado):
   - **Progresso do projeto** (log geral, mais recente no topo): uma entrada por commit. ``## YYYY-MM-DD — Fase N, commit local `hash` `` + worktree usada + resumo de 1-3 linhas + os contadores do item 1 + link `[Registro de progresso — Fase N](...)`.
   - **`📓 Progresso — Fase N`**: um tópico por commit, título `## YYYY-MM-DD — tipo: resumo curto` (tipo = prefixo do commit: `feat`/`fix`/`refactor`...). Corpo nesta ordem: **Status** (commit local / worktree / mergeado ou não na main) → **O problema** (sintoma + causa raiz, analogia curta se ajudar) → **A correção** (o que mudou, com bloco de código do trecho relevante, arquivo comentado no topo do bloco) → **Testes de regressão adicionados** (lista numerada, com destaque pro teste que pegaria o bug antes de existir) → **Checklist de commit** (cada item ✅) → **Lição pra próxima vez** (generalização, pra não repetir a causa raiz em outro lugar).

   Notas objetivas, sem enrolação.
4. Commit local. Só depois de 1-3.

## 6. Parar no commit

Commit é local e fica pronto pra push. **Push e merge são decisão do usuário** — nunca executar por conta própria, nunca commitar direto na `main`. Ao terminar, dizer o que ficou pronto e qual worktree/branch está esperando.
