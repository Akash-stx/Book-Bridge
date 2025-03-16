import 'dart:io';
import 'dart:isolate';
import 'package:book_bridge/main.dart';
import 'package:book_bridge/pdfService/processed_pdf_data.dart';
import 'package:book_bridge/pdfService/utils/per_page_Info.dart';
import 'package:book_bridge/pdfService/utils/per_pdf_slice_info.dart';
import 'package:book_bridge/pdfService/utils/status_enum.dart';
import 'package:book_bridge/pdfService/utils/thread_communication.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:ui';
import 'package:path/path.dart' as path;

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
  String fileName = path.basename(PathOfPdf);

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
    await Future.delayed(const Duration(milliseconds: 1));
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

    PdfDocument newPdfFile = getNewPdfFileInstance(loadedDocument);
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
        //allow 7% regular internal to check cancel call refrence is true or not
        await Future.delayed(const Duration(milliseconds: 1));
        cancelTime = 0;
      }
      cancelTime++;

      PdfPage loadedPage = loadedDocument.pages[i];

      //issue 01 -> some pdf faced issue of copying after disposing so now it only disposed on succesfull copy

      int pageSize = getPageSize(loadedPage);
      bool isTxtReadable = isTextPresent(
        loadedDocument,
        i,
      );

      if (isTxtReadable && pageSize < maximumSize) {
        if (currentSlizeSizeinbyte + pageSize < maximumSize) {
          currentSlizeSizeinbyte += pageSize;
          // issue 01 -> resolution disposing one succesfull copy
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
          savePdf("$dirPath${currentSlize + 1}-$fileName", newPdfFile);
          pdfSliceAloowedToProcess[currentSlize + 1] =
              PerPdfSliceInfo(pdf: newPdfFile, size: currentSlizeSizeinbyte);
          ++currentSlize;

          newPdfFile = getNewPdfFileInstance(loadedDocument);

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
    }

    if (isAnySliceOfPdfCreated) {
      callback?.call(
          "The PDF bundle is now ready for translation", currentPercentage);
      savePdf("$dirPath${currentSlize + 1}-$fileName", newPdfFile);
      pdfSliceAloowedToProcess[currentSlize + 1] =
          PerPdfSliceInfo(pdf: newPdfFile, size: currentSlizeSizeinbyte);
    }
    final PdfProcessedData result = PdfProcessedData(
        mainPdfInstance: loadedDocument,
        pathOfPdf: PathOfPdf,
        pdfName: PathOfPdf,
        pdfSliceAloowedToProcess: pdfSliceAloowedToProcess,
        perPageInfo: perPageInfo);
    await Future.delayed(const Duration(milliseconds: 1));
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
  PdfDocument newDummydocument = PdfDocument();
  PdfTemplate template = loadedPage.createTemplate();
  newDummydocument.pageSettings.margins.all = 0;
  PdfPage page = newDummydocument.pages.add();

  page.graphics.drawPdfTemplate(
      template, const Offset(0, 0), loadedPage.getClientSize());
  List<int> pdfsize = newDummydocument.saveSync();
  //issue 01
  //newDummydocument.dispose(); some issue with this dispose and template -> some pdf faced issue like template
  // is not able to copy after disposeing -> currently beliving that garbage will collect this after this method stack exit
  return pdfsize.length;
}

void copyPage(PdfDocument documentToAdd, PdfPage loadedPage) {
  try {
    PdfTemplate template = loadedPage.createTemplate();
    PdfPage page = documentToAdd.pages.add();
    page.graphics.drawPdfTemplate(
        template, const Offset(0, 0), loadedPage.getClientSize());
  } catch (e) {
    print("Copy failed");
  }
}

bool isTextPresent(PdfDocument loadedDocument, int pagenumber) {
  String text = PdfTextExtractor(loadedDocument)
      .extractText(startPageIndex: pagenumber, endPageIndex: pagenumber);
  return text.isNotEmpty;
}

PdfDocument getNewPdfFileInstance(PdfDocument loadedDocument) {
  PdfDocument newPdfFile = PdfDocument();
  print(loadedDocument.pageSettings.width);
  print(loadedDocument.pageSettings.height);
  newPdfFile.pageSettings.size = Size(
      loadedDocument.pageSettings.width, loadedDocument.pageSettings.height);
  newPdfFile.pageSettings.setMargins(0, 0, 0, 0);
  newPdfFile.pageSettings.orientation = loadedDocument.pageSettings.orientation;
  newPdfFile.pageSettings.rotate = loadedDocument.pageSettings.rotate;

  return newPdfFile;
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

void savePdf(String fileName, PdfDocument slicedPdfObject) {
  File(fileName).writeAsBytes(slicedPdfObject.saveSync());
  slicedPdfObject.dispose();
}
