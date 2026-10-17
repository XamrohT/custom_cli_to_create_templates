import 'dart:io';

/// Repositórios-fonte de cada stack (fonte da verdade do código gerado).
const defaultTemplates = {
  'flutter': 'https://github.com/XamrohT/flutter-template.git',
  'react': 'https://github.com/XamrohT/react-template.git',
  'nest': 'https://github.com/XamrohT/nest-template.git',
};

const stacks = ['flutter', 'react', 'nest'];

/// Template já disponível em disco: pasta local ou clone raso temporário.
class TemplateSource {
  TemplateSource._(this.dir, this._tmp);

  final Directory dir;
  final Directory? _tmp;

  static Future<TemplateSource> open(String template, {String? ref}) async {
    final isRemote =
        RegExp(r'^(https?://|git@|ssh://|git://)').hasMatch(template);
    if (!isRemote && Directory(template).existsSync()) {
      return TemplateSource._(Directory(template), null);
    }
    final tmp =
        Directory.systemTemp.createTempSync('custom_cli_to_create_templates_');
    await _clone(template, tmp.path, ref: ref);
    return TemplateSource._(tmp, tmp);
  }

  void dispose() {
    try {
      _tmp?.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows pode segurar arquivos do .git por instantes; a pasta é temporária.
    }
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
