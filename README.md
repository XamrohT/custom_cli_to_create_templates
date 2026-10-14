# custom_flutter

CLI em Dart que cria projetos Flutter com uma arquitetura padrão (Modular + MobX + UseCase/Repository + Dio) e gera módulos novos.

Faz parte de um par de repositórios:

| Repositório | Papel |
|---|---|
| [`custom_flutter`](https://github.com/XamrohT/custom_flutter) (este) | A ferramenta. Não contém o template. |
| [`flutter-template`](https://github.com/XamrohT/flutter-template) | **Fonte da verdade** do código do projeto gerado. |

## Instalar
```bash
dart pub global activate --source git https://github.com/XamrohT/custom_flutter.git
```
Garanta que o diretório de executáveis do pub está no PATH (`<PUB_CACHE>/bin`; no Windows costuma ser `%LOCALAPPDATA%\Pub\Cache\bin`). Atualizar = rodar o comando de novo.

Pré-requisitos: Flutter/Dart e git no PATH.

## Comandos
```bash
custom_flutter create <nome_snake_case> --org br.com.empresa [--title "Meu App"] [--platforms web,android,ios] [--no-install] [--no-git] [--template <url|pasta>] [--ref <branch|tag>]
custom_flutter add module <nome_snake_case>      # dentro da raiz de um projeto gerado
```
Atenção: flags longas usam dois hífens (`--org`); `-org` é lido como `-o -r -g`.

Documentação de arquitetura e fluxo para agentes/LLMs: veja [AGENTS.md](AGENTS.md).
