import 'package:book_bridge/pdfService/utils/per_page_Info.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfProcessedData {
  final String pathOfPdf;
  final String pdfName;
  final List<PerPdfPageInfo> perPageInfo;
  final List<PdfDocument> pdfSliceAloowedToProcess;
  //needed for disposing
  final PdfDocument mainPdfInstance;

  PdfProcessedData(
      {required this.perPageInfo,
      required this.pdfSliceAloowedToProcess,
      required this.pathOfPdf,
      required this.pdfName,
      required this.mainPdfInstance});
}
