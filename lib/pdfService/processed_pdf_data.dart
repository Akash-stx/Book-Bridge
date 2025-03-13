import 'package:book_bridge/pdfService/utils/per_page_Info.dart';
import 'package:book_bridge/pdfService/utils/per_pdf_slice_info.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfProcessedData {
  final String pathOfPdf;
  final String pdfName;
  final List<PerPdfPageInfo?> perPageInfo;
  final List<PerPdfSliceInfo?> pdfSliceAloowedToProcess;
  //needed for disposing do not forget to dispose mainPdfInstance
  final PdfDocument mainPdfInstance;
  late int pdfReuploadStatus;
  late int totalPDFGoingToProcess;

  PdfProcessedData(
      {required this.perPageInfo,
      required this.pdfSliceAloowedToProcess,
      required this.pathOfPdf,
      required this.pdfName,
      required this.mainPdfInstance})
      : pdfReuploadStatus = pdfSliceAloowedToProcess.length ?? -1,
        totalPDFGoingToProcess = pdfSliceAloowedToProcess.length ?? -1;

  void setReuplodedPdfPath({int? index, String? path}) {
    if (index != null &&
        index < totalPDFGoingToProcess &&
        path != null &&
        path.isNotEmpty) {
      PerPdfSliceInfo pdfinstance = pdfSliceAloowedToProcess[index]!;
      pdfinstance.pathOftranslatedPdf = path;
      pdfinstance.isSubmitedAfterTransulation = true;
      --pdfReuploadStatus;
    }
  }
}
