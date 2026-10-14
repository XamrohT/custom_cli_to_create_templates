import 'dart:io';

Future<void> runProcess(String exe, List<String> args, {String? cwd}) async {
  stdout.writeln('\$ $exe ${args.join(' ')}');
  final proc = await Process.start(
    exe,
    args,
    workingDirectory: cwd,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await proc.exitCode;
  if (code != 0)
    throw ProcessException(exe, args, 'saiu com código $code', code);
}
