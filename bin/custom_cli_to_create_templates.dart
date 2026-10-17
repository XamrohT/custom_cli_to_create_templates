import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:custom_cli_to_create_templates/src/commands/add_command.dart';
import 'package:custom_cli_to_create_templates/src/commands/create_command.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner<int>(
    'custom_cli_to_create_templates',
    'Gera projetos Flutter, React e Nest a partir dos nossos templates e adiciona módulos.',
  )
    ..addCommand(CreateCommand())
    ..addCommand(AddCommand());
  try {
    exitCode = await runner.run(args) ?? 0;
  } on UsageException catch (e) {
    stderr.writeln(e);
    exitCode = 64;
  } on ProcessException catch (e) {
    stderr.writeln('Falhou: ${e.executable} ${e.arguments.join(' ')} (${e.message})');
    exitCode = e.errorCode == 0 ? 1 : e.errorCode;
  }
}
