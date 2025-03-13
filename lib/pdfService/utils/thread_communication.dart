import 'package:book_bridge/pdfService/utils/status_enum.dart';

class ThreadCommunication {
  final Status status;
  final List<dynamic>? arguments;

  ThreadCommunication({required this.status, this.arguments});
}

ThreadCommunication messageThread(
    {required Status name, List<dynamic>? arguments}) {
  return ThreadCommunication(status: name, arguments: arguments);
}
