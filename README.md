# custom_flutter

CLI para criar projetos Flutter com a nossa arquitetura (Modular + MobX + UseCase/Repository + Dio).
A fonte do template é o repositório `flutter-template`: nada fica copiado aqui.

## Instalar
```bash
dart pub global activate --source git <url-deste-repo>
# ou local:
dart pub global activate --source path E:/Development/custom_flutter
```
Coloque o diretório de executáveis do pub no PATH (aqui: `E:\pub-cache\bin`).

## Usar
```bash
custom_flutter create meu_app --org br.com.empresa [--title "Meu App"] [--no-install] [--no-git]
cd meu_app
custom_flutter add module pedidos
```

## Como o `create` funciona
1. `flutter create --empty` (plataformas atualizadas).
2. `git clone --depth 1` do template numa pasta temporária (apagada no fim), sem o `.git`.
3. Copia `lib/`, `test/`, `pubspec.yaml` etc. renomeando pacote e título.
4. `pub get`, `intl_utils`, `build_runner` e `git init` novo: o projeto não tem vínculo com o repositório do template.

Opções: `--template <url|pasta>` (outro repo ou pasta local, útil offline) e `--ref <branch|tag>` para fixar versão.
Como o repositório é privado, precisa de git autenticado (`gh auth login`).
