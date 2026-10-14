import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../names.dart';
import '../process_runner.dart';

const _tplPackage = 'flutter_backoffice_template';
const defaultTemplateRepo = 'https://github.com/XamrohT/flutter-template.git';

/// Itens do template que não devem ir para o projeto novo.
const _skip = {
  '.git',
  '.metadata',
  'pubspec.lock',
  'tool',
  'build',
  '.dart_tool'
};

class CreateCommand extends Command<int> {
  @override
  final name = 'create';
  @override
  final description = 'Cria um projeto Flutter já com a estrutura do template.';
  @override
  String get invocation =>
      'custom_flutter create <nome_do_projeto> [--org br.com.empresa]';

  CreateCommand() {
    argParser
      ..addOption('org',
          abbr: 'o',
          defaultsTo: 'br.com.example',
          help: 'Organização (applicationId).')
      ..addOption('title',
          abbr: 't', help: 'Título do app. Padrão: nome em Title Case.')
      ..addOption('template',
          defaultsTo: defaultTemplateRepo,
          help: 'URL git ou pasta local do template.')
      ..addOption('ref',
          help: 'Branch ou tag do template (padrão: branch principal).')
      ..addFlag('git', defaultsTo: true, help: 'Roda git init no projeto novo.')
      ..addOption('platforms',
          defaultsTo: 'web,android,ios', help: 'Plataformas do flutter create.')
      ..addFlag('install',
          defaultsTo: true, help: 'Roda pub get, intl_utils e build_runner.');
  }

  @override
  Future<int> run() async {
    if (argResults!.rest.length != 1)
      usageException('Informe o nome do projeto.');
    final projectName = argResults!.rest.first;
    if (!isValidPackageName(projectName)) {
      usageException(
          'Nome inválido "$projectName": use snake_case (ex.: meu_app).');
    }
    final org = argResults!['org'] as String;
    final title = (argResults!['title'] as String?) ??
        projectName
            .split('_')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
    if (Directory(projectName).existsSync())
      usageException('A pasta "$projectName" já existe.');

    // 1. Plataformas atualizadas vindas do próprio Flutter.
    await runProcess('flutter', [
      'create',
      '--empty',
      '--org',
      org,
      '--project-name',
      projectName,
      '--platforms',
      argResults!['platforms'] as String,
      projectName,
    ]);

    // 2. Obtém o template (clone raso em pasta temporária ou pasta local).
    final template = argResults!['template'] as String;
    Directory src;
    Directory? tmp;
    final isRemote =
        RegExp(r'^(https?://|git@|ssh://|git://)').hasMatch(template);
    if (!isRemote && Directory(template).existsSync()) {
      src = Directory(template);
    } else {
      tmp = Directory.systemTemp.createTempSync('custom_flutter_');
      final ref = argResults!['ref'] as String?;
      await _clone(template, tmp.path, ref: ref);
      src = tmp;
    }

    try {
      for (final d in ['lib', 'test']) {
        final dir = Directory(p.join(projectName, d));
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      }
      var count = 0;
      await for (final e in src.list(recursive: true, followLinks: false)) {
        if (e is! File) continue;
        final rel = p.relative(e.path, from: src.path);
        if (p.split(rel).any(_skip.contains)) continue;
        // Não sobrescreve as plataformas geradas pelo flutter create.
        if (const {'android', 'ios', 'web', 'windows', 'linux', 'macos'}
            .contains(p.split(rel).first)) continue;
        final out = File(p.join(projectName, rel))..createSync(recursive: true);
        final text = (await e.readAsString())
            .replaceAll(_tplPackage, projectName)
            .replaceAll('Flutter Template', title)
            .replaceAll('Template Flutter', title);
        out.writeAsStringSync(text);
        count++;
      }
      stdout.writeln('Template aplicado ($count arquivos).');
    } finally {
      try {
        tmp?.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows pode segurar arquivos do .git por instantes; a pasta é temporária.
      }
    }

    // 3. Dependências e geradores.
    if (argResults!['install'] as bool) {
      await runProcess('flutter', ['pub', 'get'], cwd: projectName);
      await runProcess('flutter', ['pub', 'run', 'intl_utils:generate'],
          cwd: projectName);
      await runProcess('dart',
          ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
          cwd: projectName);
    }
    if (argResults!['git'] as bool) {
      await runProcess('git', ['init', '-q', '-b', 'main'], cwd: projectName);
    }
    stdout.writeln('\nPronto! cd $projectName && flutter run -d chrome');
    return 0;
  }
}

/// Clone raso sem prompts interativos. Usa o credential helper do `gh` se estiver logado
/// (o Git Credential Manager padrão abre uma janela e trava em ambientes sem UI).
Future<void> _clone(String url, String dest, {String? ref}) async {
  final gh = await Process.run('gh', ['auth', 'status'], runInShell: true)
      .then((r) => r.exitCode == 0, onError: (_) => false);
  final args = [
    if (gh) ...[
      '-c',
      'credential.helper=',
      '-c',
      'credential.helper=!gh auth git-credential'
    ],
    'clone',
    '--depth',
    '1',
    if (ref != null) ...['--branch', ref],
    url,
    dest,
  ];
  stdout.writeln('\$ git clone --depth 1 $url');
  final proc = await Process.start('git', args,
      environment: {'GIT_TERMINAL_PROMPT': '0', 'GCM_INTERACTIVE': 'never'},
      mode: ProcessStartMode.inheritStdio);
  final code =
      await proc.exitCode.timeout(const Duration(minutes: 2), onTimeout: () {
    proc.kill();
    return -1;
  });
  if (code != 0) {
    throw ProcessException(
        'git',
        ['clone', url],
        'falhou (código $code). Para repositório privado, rode `gh auth login`.',
        code);
  }
}
