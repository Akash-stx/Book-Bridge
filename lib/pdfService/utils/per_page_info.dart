import 'package:syncfusion_flutter_pdf/pdf.dart';

class PerPdfPageInfo {
  final int pageNumber;
  final bool isPackedForProcess;
  final int? packedPdfNumber;
  final PdfPage? failedPages;

  PerPdfPageInfo(
      {required this.pageNumber,
      required this.isPackedForProcess,
      required this.packedPdfNumber,
      this.failedPages});
}
