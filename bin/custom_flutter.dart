import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:custom_flutter/src/commands/add_command.dart';
import 'package:custom_flutter/src/commands/create_command.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner<int>(
    'custom_flutter',
    'Gera projetos Flutter com a nossa arquitetura (Modular + MobX + Dio).',
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
