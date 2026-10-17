# custom_cli_to_create_templates

CLI em Dart que cria projetos **Flutter, React e Nest** a partir dos nossos templates (cada um já com a arquitetura modular padrão) e gera módulos novos.

Cada stack tem um repositório-template, que é a **fonte da verdade** do código gerado. A CLI não contém nenhum deles; clona na hora.

| Stack | Template | Nome do projeto | Módulo novo |
|---|---|---|---|
| `flutter` (padrão) | [`flutter-template`](https://github.com/XamrohT/flutter-template) | snake_case | gerado pela CLI |
| `react` | [`react-template`](https://github.com/XamrohT/react-template) (privado) | kebab-case | `npm run add:module` do template |
| `nest` | [`nest-template`](https://github.com/XamrohT/nest-template) (privado) | kebab-case | `npm run add:module` do template |

## Instalar
```bash
dart pub global activate --source git https://github.com/XamrohT/custom_cli_to_create_templates.git
```
Garanta que o diretório de executáveis do pub está no PATH (`<PUB_CACHE>/bin`; veja `dart pub global list` e a variável `PUB_CACHE`, no Windows costuma ser `%LOCALAPPDATA%\Pub\Cache\bin`). Atualizar = rodar o comando de novo.

Pré-requisitos: git no PATH; Flutter/Dart para `flutter`; Node.js e npm para `react` e `nest`. Os templates `react` e `nest` são privados: faça `gh auth login` antes.

## Comandos
```bash
# Flutter (padrão)
custom_cli_to_create_templates create meu_app --org br.com.empresa [--title "Meu App"] [--platforms web,android,ios]
# React
custom_cli_to_create_templates create meu-front --stack react [--title "Meu Front"]
# Nest
custom_cli_to_create_templates create minha-api --stack nest [--title "Minha API"]

# Módulo novo, dentro da raiz de um projeto gerado (a stack é detectada pela pasta)
custom_cli_to_create_templates add module pedidos
custom_cli_to_create_templates add module pedidos --use-case listar-pedidos   # só nest
```
Opções comuns do `create`: `--stack/-s`, `--title/-t`, `--no-install`, `--no-git`, `--template <url|pasta>`, `--ref <branch|tag>`. `--org` e `--platforms` valem só para Flutter.

Atenção: flags longas usam dois hífens (`--org`); `-org` é lido como `-o -r -g`.

Documentação de arquitetura e fluxo para agentes/LLMs: veja [AGENTS.md](AGENTS.md).
