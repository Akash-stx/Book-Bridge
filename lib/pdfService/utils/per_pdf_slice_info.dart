import 'package:syncfusion_flutter_pdf/pdf.dart';

class PerPdfSliceInfo {
  final int size;
  final PdfDocument pdf;
  bool isSubmitedAfterTransulation = false;
  String pathOftranslatedPdf = "";

  PerPdfSliceInfo({required this.size, required this.pdf});
}
