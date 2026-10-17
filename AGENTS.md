# AGENTS.md — custom_cli_to_create_templates

Guia para LLMs/agentes que usam ou modificam este repositório.

## O que é
CLI Dart (`bin/custom_cli_to_create_templates.dart`, pacote `args`) com dois comandos: `create` e `add module`. Ela **não guarda template**: o código do projeto vem do repositório `flutter-template` em tempo de execução.

## Como os dois repositórios interagem
```
custom_cli_to_create_templates create meu_app --org br.com.x
  1. flutter create --empty --org ... --project-name meu_app   (gera android/ios/web atuais)
  2. git clone --depth 1 <template> -> pasta temporária        (padrão: github.com/XamrohT/flutter-template)
  3. apaga lib/ e test/ do projeto; copia os arquivos do template, exceto:
       .git, .metadata, pubspec.lock, tool/, build/, .dart_tool/ e as pastas de plataforma
     substituindo o texto:  flutter_backoffice_template -> <nome>,  "Flutter Template"/"Template Flutter" -> <título>
  4. apaga a pasta temporária
  5. flutter pub get; flutter pub run intl_utils:generate; dart run build_runner build --delete-conflicting-outputs
  6. git init -b main  (projeto novo, sem remoto nem histórico do template)
```
`add module <nome>` **não usa o template**: gera os arquivos a partir de strings em `lib/src/commands/add_command.dart` e registra a rota em `lib/modules/app/app_module.dart` do projeto atual.

## Contratos que não podem quebrar (acoplamento com flutter-template)
- Nome do pacote placeholder: `flutter_backoffice_template` (constante `_tplPackage` em `create_command.dart`). Se o template for renomeado, atualize aqui.
- Strings de título trocadas: `Flutter Template` e `Template Flutter`.
- `add module` assume que existem `lib/core/protocols/use_case.dart` (`UseCase<T, P>`), `lib/modules/app/app_module.dart` com `List<ModularRoute> get routes => [` e imports no topo, e as dependências `flutter_modular`, `mobx`, `flutter_mobx`.
- O template pode ser trocado com `--template <url|pasta>`; pasta local serve para testar mudanças sem push.

## Onde mudar o quê
| Quero... | Edite |
|---|---|
| mudar a estrutura/arquitetura dos projetos novos | **`flutter-template`** (não este repo) |
| mudar o esqueleto gerado por `add module` | `lib/src/commands/add_command.dart` |
| mudar o fluxo do `create` | `lib/src/commands/create_command.dart` |

## Armadilhas conhecidas
- Clone com credential helper padrão do Git for Windows pode abrir janela e travar; `_clone` usa `gh auth git-credential` se `gh` estiver logado, `GIT_TERMINAL_PROMPT=0` e timeout de 2 min.
- `Directory.existsSync` com URL lança erro no Windows; por isso há o teste `isRemote` antes.
- No Windows o shell pode manter a pasta atual aberta e impedir apagar/renomear.

## Validar mudanças
```bash
dart analyze
D=$(mktemp -d) && cd $D && dart run <caminho>/bin/custom_cli_to_create_templates.dart create x_app --template <caminho-do-flutter-template>
cd x_app && flutter analyze && flutter test && custom_cli_to_create_templates add module pedidos
```
