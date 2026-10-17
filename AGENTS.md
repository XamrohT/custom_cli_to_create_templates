# AGENTS.md — custom_cli_to_create_templates

Guia para LLMs/agentes que usam ou modificam este repositório.

## O que é
CLI Dart (`bin/custom_cli_to_create_templates.dart`, pacote `args`) com dois comandos: `create` e `add module`. Ela **não guarda template**: o código do projeto vem de um repositório por stack (`flutter-template`, `react-template`, `nest-template`, mapa `defaultTemplates` em `lib/src/template_source.dart`) em tempo de execução. `create --stack flutter|react|nest` escolhe a stack (padrão: flutter).

## Como a CLI e os templates interagem
### Flutter
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
`add module <nome>` (Flutter, detectado por `pubspec.yaml`) **não usa o template**: gera os arquivos a partir de strings em `lib/src/commands/add_command.dart` e registra a rota em `lib/modules/app/app_module.dart` do projeto atual.

### React e Nest
```
custom_cli_to_create_templates create meu-front --stack react      (nome em kebab-case)
  1. git clone --depth 1 <template da stack> -> pasta temporária
  2. copia tudo, exceto: .git, node_modules, dist, coverage, .env
  3. npm run rename -- <nome> <título>   (script do próprio template), depois APAGA tool/rename-project.mjs
     e a entrada "rename" do package.json (só serve uma vez)
  4. npm install;  git init -b main
```
`add module <nome>` (detectado por `package.json` sem `pubspec.yaml`) **delega** ao script do template: roda `npm run add:module -- <nome> [--use-case <x>]`. A CLI não tem o esqueleto desses módulos; ele vive em `tool/add-module.mjs` de cada template.

## Contratos que não podem quebrar (acoplamento com os templates)
- Nome do pacote placeholder: `flutter_backoffice_template` (constante `_tplPackage` em `create_command.dart`). Se o template for renomeado, atualize aqui.
- Strings de título trocadas: `Flutter Template` e `Template Flutter`.
- `add module` assume que existem `lib/core/protocols/use_case.dart` (`UseCase<T, P>`), `lib/modules/app/app_module.dart` com `List<ModularRoute> get routes => [` e imports no topo, e as dependências `flutter_modular`, `mobx`, `flutter_mobx`.
- React/Nest: o template precisa ter `tool/rename-project.mjs` (aceita `<nome-kebab> [título]`) e scripts `rename` e `add:module` no `package.json`. Sem `tool/rename-project.mjs`, o `create` pula a renomeação; sem `add:module`, o `add module` recusa.
- `--org` e `--platforms` são só Flutter; passar com react/nest dá erro de uso.
- O template pode ser trocado com `--template <url|pasta>`; pasta local serve para testar mudanças sem push.

## Onde mudar o quê
| Quero... | Edite |
|---|---|
| mudar a estrutura/arquitetura dos projetos novos | **o repositório-template da stack** (não este repo) |
| mudar o esqueleto de módulo React/Nest | `tool/add-module.mjs` do `react-template`/`nest-template` |
| acrescentar uma stack nova | `defaultTemplates` e `stacks` em `template_source.dart`, e o ramo em `create_command.dart` |
| mudar o esqueleto gerado por `add module` | `lib/src/commands/add_command.dart` |
| mudar o fluxo do `create` | `lib/src/commands/create_command.dart` |

## Armadilhas conhecidas
- Mudou o código e o comando global continua antigo? Apague `.dart_tool/pub/bin` e rode `dart pub global activate --source path <repo>` de novo (o snapshot compilado fica velho).
- Clone com credential helper padrão do Git for Windows pode abrir janela e travar; `_clone` (em `template_source.dart`) usa `gh auth git-credential` se `gh` estiver logado, `GIT_TERMINAL_PROMPT=0` e timeout de 2 min.
- `Directory.existsSync` com URL lança erro no Windows; por isso há o teste `isRemote` antes.
- No Windows o shell pode manter a pasta atual aberta e impedir apagar/renomear.

## Validar mudanças
```bash
dart analyze
D=$(mktemp -d) && cd $D && dart run <caminho>/bin/custom_cli_to_create_templates.dart create x_app --template <caminho-do-flutter-template>
cd x_app && flutter analyze && flutter test && custom_cli_to_create_templates add module pedidos
# react / nest (precisa de gh logado: os templates são privados)
custom_cli_to_create_templates create x-front --stack react && cd x-front && custom_cli_to_create_templates add module pedidos && npm run lint && npm test && npm run build
custom_cli_to_create_templates create x-api --stack nest && cd x-api && custom_cli_to_create_templates add module pedidos --use-case listar-pedidos && npm run check
```
