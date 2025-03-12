import 'dart:io';
import 'package:book_bridge/pdfService/processed_pdf_data.dart';
import 'package:book_bridge/pdfService/utils/per_page_Info.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:ui';

const int maximumSize = 10 * 1024 * 1024; // 10MB in bytes

Future<PdfProcessedData?> processPdf(
    {String PathOfPdf = "/storage/emulated/0/Download/example.pdf"}) async {
  //load pdf to memory via path
  PdfDocument loadedDocument =
      PdfDocument(inputBytes: File(PathOfPdf).readAsBytesSync());

  final int pageSize = loadedDocument.pages.count;

  int currentSlize = 0;
  int currentSlizeSizeinbyte = 0;

  final List<PerPdfPageInfo?> perPageInfo =
      List.filled(pageSize, null, growable: false);

  final List<PdfDocument?> pdfSliceAloowedToProcess =
      List.filled(pageSize, null, growable: false);

  PdfDocument newPdfFile = getNewPdfFileInstance();

  for (var i = 0; i < pageSize; i++) {
    PdfPage loadedPage = loadedDocument.pages[i];
    int pageSize = getPageSize(loadedPage);
    bool isTxtReadable = isTextPresent(loadedDocument, i);
    if (isTxtReadable && pageSize < maximumSize) {
      if (currentSlizeSizeinbyte + pageSize < maximumSize) {
        currentSlizeSizeinbyte += pageSize;
        copyPage(newPdfFile, loadedPage);

        perPageInfo[i] = PerPdfPageInfo(
            isPackedForProcess: true,
            packedPdfNumber: currentSlize,
            pageNumber: i);
      } else {
        pdfSliceAloowedToProcess[currentSlize++] = newPdfFile;

        newPdfFile = getNewPdfFileInstance();

        currentSlizeSizeinbyte = 0;
        copyPage(newPdfFile, loadedPage);

        perPageInfo[i] = PerPdfPageInfo(
            isPackedForProcess: true,
            packedPdfNumber: currentSlize,
            pageNumber: i);
      }
    } else {
      perPageInfo[i] = PerPdfPageInfo(
          isPackedForProcess: false,
          packedPdfNumber: null,
          pageNumber: i,
          failedPages: loadedPage);
    }
  }
  pdfSliceAloowedToProcess[currentSlize++] = newPdfFile;

  // //Set margin for all the pages

  // //Get the first page from the document.
  // PdfPage loadedPage = loadedDocument.pages[0];
  // //Extracts the text from pages 1 to 3
  // String text = PdfTextExtractor(loadedDocument)
  //     .extractText(startPageIndex: 0, endPageIndex: 0);
  // //Create a PDF Template.
  // PdfTemplate template = loadedPage.createTemplate();
  // //Create a new PDF document.
  // PdfDocument document = PdfDocument();

  // document.pageSettings.margins.all = 0;

  // //Add the page.
  // PdfPage page = document.pages.add();
  // //Create the graphics.
  // PdfGraphics graphics = page.graphics;
  // //Draw the template.
  // graphics.drawPdfTemplate(template, const Offset(0, 0));
  // List<int> pdfsize = document.saveSync();

  // const int tenMB = 10 * 1024 * 1024; // 10MB in bytes

  // // Get the PDF as bytes
  print("is page redable $perPageInfo");
  print("PDF size of number  is  $pdfSliceAloowedToProcess");
  // if (pdfsize.length < tenMB) {
  //   print("PDF size is less than 10MB");
  // } else {
  //   print("PDF size is 10MB or more");
  // }
  // //Save and dispose of the PDF document.
  File("/storage/emulated/0/Download/output_page_new.pdf")
      .writeAsBytes(pdfSliceAloowedToProcess[0]!.saveSync());
  loadedDocument.dispose();
  return null;
}

int getPageSize(PdfPage loadedPage) {
  PdfDocument document = PdfDocument();
  document.pageSettings.margins.all = 0;
  PdfPage page = document.pages.add();
  PdfTemplate template = loadedPage.createTemplate();
  page.graphics.drawPdfTemplate(template, const Offset(0, 0));
  List<int> pdfsize = document.saveSync();
  document.dispose();
  return pdfsize.length;
}

void copyPage(PdfDocument document, PdfPage copyFrom) {
  PdfPage page = document.pages.add();
  PdfTemplate template = copyFrom.createTemplate();
  page.graphics.drawPdfTemplate(template, const Offset(0, 0));
}

bool isTextPresent(PdfDocument loadedDocument, int pagenumber) {
  String text = PdfTextExtractor(loadedDocument)
      .extractText(startPageIndex: pagenumber, endPageIndex: pagenumber);
  return text.isNotEmpty;
}

PdfDocument getNewPdfFileInstance() {
  PdfDocument newPdfFile = PdfDocument();
  newPdfFile.pageSettings.margins.all = 0;
  return newPdfFile;
}
