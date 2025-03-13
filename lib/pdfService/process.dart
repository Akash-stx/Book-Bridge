import 'dart:io';
import 'dart:isolate';
import 'package:book_bridge/pdfService/processed_pdf_data.dart';
import 'package:book_bridge/pdfService/utils/per_page_Info.dart';
import 'package:book_bridge/pdfService/utils/per_pdf_slice_info.dart';
import 'package:book_bridge/pdfService/utils/status_enum.dart';
import 'package:book_bridge/pdfService/utils/thread_communication.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:ui';

ReceivePort receivePort = ReceivePort();
SendPort? passDataTomainUI;
const int maximumSize = 10 * 1024 * 1024; // 10MB in bytes
bool cancelledPdfProcess = false;
bool isAnyPdfProcess = false;

//POINT WHERE ALL THE FUNCITONS ARE MAPPED
// IT IS CALLED BY ANOTHER THREAD
void processPdfViaThreadConnect(SendPort mainSendPort) async {
  passDataTomainUI = mainSendPort;
  mainSendPort.send(ThreadCommunication(
      status: Status.connectBack, arguments: [receivePort.sendPort]));
/************************************** */
  PdfProcessedData? pdfinsatnce;
/************************************** */
  receivePort.listen((message) {
    try {
      switch (message.status) {
        case Status.stop:
          print("Isolate stopping...");
          receivePort.close();
          Isolate.exit();
          break;
        case Status.convertSelectedPdf:
          if (pdfinsatnce != null) {
            pdfinsatnce!.mainPdfInstance.dispose();
            pdfinsatnce = null;
          }

          processPdfToBundles(
            PathOfPdf: getArgumentAt(message: message, index: 0),
            callback: (event, percentage) {
              mainSendPort.send(ThreadCommunication(
                  status: Status.pdfConversionOutPutCallBack,
                  arguments: [event, percentage]));
            },
          ).then((result) {
            pdfinsatnce = result;
          }).whenComplete(() {
            isAnyPdfProcess = false;
            mainSendPort.send(ThreadCommunication(
                status: Status.pdfConversionSuccess,
                arguments: [pdfinsatnce != null ? "success" : "failed"]));
          });
          break;

        case Status.initiatecancelPdfProcess:
          if (isAnyPdfProcess) {
            cancelledPdfProcess = true;
          } else {
            cancelledPdfProcess = false;
          }
          break;
        case Status.log:
          print(message.arguments[0]);
          break;
        default:
          print("no fuction declared");
      }
    } catch (e) {
      print(e.toString());
    }
  });
}

Future<PdfProcessedData?> processPdfToBundles({
  String PathOfPdf = "/storage/emulated/0/Download/example.pdf",
  void Function(String event, int? percentage)? callback,
}) async {
  isAnyPdfProcess = true;
  try {
    //load pdf to memory via path
    PdfDocument loadedDocument =
        PdfDocument(inputBytes: File(PathOfPdf).readAsBytesSync());

    final int pageCount = loadedDocument.pages.count;
    final int tenthPercentage = ((10 / 100) * pageCount).toInt();
    final int percentageUsedForTotalCalculation = pageCount +
        tenthPercentage *
            2; // manually just to get percenateg like style from for loop and index are adding other 20 % more to total page
    int currentPercentage =
        percentageCalculate(percentageUsedForTotalCalculation, tenthPercentage);

    callback?.call("Total Pages Found: $pageCount", currentPercentage);
    await Future.delayed(Duration(milliseconds: 1));
    if (cancelledPdfProcess) {
      cancelledPdfProcess = false;
      loadedDocument.dispose();
      passDataTomainUI!
          .send(ThreadCommunication(status: Status.canceledSuccess));
      return null;
    }
    int currentSlize = 0;
    int currentSlizeSizeinbyte = 0;

    final List<PerPdfPageInfo?> perPageInfo =
        List.filled(pageCount, null, growable: false);

    final List<PerPdfSliceInfo?> pdfSliceAloowedToProcess =
        List.filled(pageCount, null, growable: false);

    PdfDocument newPdfFile = getNewPdfFileInstance();
    bool isAnySliceOfPdfCreated = false;
    int cancelTime = 0;
    for (var i = 0; i < pageCount; i++) {
      if (cancelledPdfProcess) {
        cancelledPdfProcess = false;
        loadedDocument.dispose();
        passDataTomainUI!
            .send(ThreadCommunication(status: Status.canceledSuccess));
        return null;
      }
      if (cancelTime / pageCount * 100 > 7) {
        //allow 7% regular internal to check cancel call
        await Future.delayed(Duration(milliseconds: 1));
        cancelTime = 0;
      }
      cancelTime++;

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
          isAnySliceOfPdfCreated = true;

          currentPercentage = percentageCalculate(
              percentageUsedForTotalCalculation, tenthPercentage, i + 1);

          callback?.call(
              "Page ${i + 1} has been successfully grouped into PDF slice $currentSlize for processing",
              currentPercentage);
        } else {
          pdfSliceAloowedToProcess[currentSlize++] =
              PerPdfSliceInfo(pdf: newPdfFile, size: currentSlizeSizeinbyte);

          newPdfFile = getNewPdfFileInstance();

          currentSlizeSizeinbyte = 0;
          copyPage(newPdfFile, loadedPage);

          perPageInfo[i] = PerPdfPageInfo(
              isPackedForProcess: true,
              packedPdfNumber: currentSlize,
              pageNumber: i);
          isAnySliceOfPdfCreated = true;
          currentPercentage = percentageCalculate(
              percentageUsedForTotalCalculation, tenthPercentage, i + 1);

          callback?.call(
              "Page ${i + 1} has been successfully grouped into PDF slice $currentSlize for processing",
              currentPercentage);
        }
      } else {
        currentPercentage = percentageCalculate(
            percentageUsedForTotalCalculation, tenthPercentage, i + 1);
        callback?.call(
            isTxtReadable
                ? "Page ${i + 1} exceeds 10MB and cannot be included in the bundled PDF"
                : "Page ${i + 1} could not be processed.",
            currentPercentage);

        perPageInfo[i] = PerPdfPageInfo(
            isPackedForProcess: false,
            packedPdfNumber: null,
            pageNumber: i,
            failedPages: loadedPage);
      }
      print("Percentage $currentPercentage %");
    }

    if (isAnySliceOfPdfCreated) {
      callback?.call(
          "The PDF bundle is now ready for translation", currentPercentage);
      pdfSliceAloowedToProcess[currentSlize++] =
          PerPdfSliceInfo(pdf: newPdfFile, size: currentSlizeSizeinbyte);
    }
    final PdfProcessedData result = PdfProcessedData(
        mainPdfInstance: loadedDocument,
        pathOfPdf: PathOfPdf,
        pdfName: PathOfPdf,
        pdfSliceAloowedToProcess: pdfSliceAloowedToProcess,
        perPageInfo: perPageInfo);
    await Future.delayed(Duration(milliseconds: 1));
    if (cancelledPdfProcess) {
      cancelledPdfProcess = false;
      loadedDocument.dispose();
      passDataTomainUI!
          .send(ThreadCommunication(status: Status.canceledSuccess));
      return null;
    }
    callback?.call("Process Completed Successfully", 100);
    return result;
  } catch (e) {
    callback?.call(e.toString(), 0);
    return null;
  }
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
  try {
    PdfPage page = document.pages.add();
    PdfTemplate template = copyFrom.createTemplate();
    page.graphics.drawPdfTemplate(template, const Offset(0, 0));
  } catch (e) {
    print("Copy failed");
  }
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

void extrass() {
  // print("is page redable $perPageInfo");
  // print("PDF size of number  is  $pdfSliceAloowedToProcess");
  // if (pdfsize.length < tenMB) {
  //   print("PDF size is less than 10MB");
  // } else {
  //   print("PDF size is 10MB or more");
  // }
  // //Save and dispose of the PDF document.
  // File("/storage/emulated/0/Download/output_page_new.pdf")
  //     .writeAsBytes(pdfSliceAloowedToProcess[0]!.saveSync());
  // loadedDocument.dispose();
}

int percentageCalculate(int total, int currentValue, [int index = 0]) {
  int percentage = (((currentValue + index) / total) * 100).toInt();
  return percentage;
}

dynamic getArgumentAt(
    {required ThreadCommunication message,
    required int index,
    dynamic defaultValue}) {
  try {
    if (message.arguments != null &&
        message.arguments!.isNotEmpty &&
        index >= 0 &&
        index < message.arguments!.length) {
      return message.arguments![index] ?? defaultValue;
    }
  } catch (e) {
    print("Error accessing index $index: $e"); // Logs the error if any
  }
  return defaultValue; // Returns null if out of bounds or any error occurs
}
