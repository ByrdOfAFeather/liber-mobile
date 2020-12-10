import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:liber/api.dart';
import 'package:liber/local_database.dart';
import 'package:liber/verify_book.dart';

Widget rowInfo(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Expanded(child: Text("$label: ")), Text(value)],
  );
}

Widget rowInfoList(String label, List<String> values) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(child: Text("$label: ")),
      Column(
        children: [...values.map((String value) => Text(value))],
      )
    ],
  );
}

Widget labeledIconButton(Icon icon, String labelText, Function onPressed) {
  return Column(
    children: [
      IconButton(
        icon: icon,
        onPressed: onPressed,
      ),
      Text(labelText)
    ],
  );
}

Widget confirmDenyButtons(Function onCancel, Function onConfirm) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      labeledIconButton(
          Icon(Icons.cancel, color: Colors.red), "Cancel", onCancel),
      labeledIconButton(
          Icon(Icons.check, color: Colors.green), "Confirm", onConfirm)
    ],
  );
}

Widget confirmBookDialog(
    BuildContext context, Book book, Function onCancel, Function onConfirm) {
  return AlertDialog(
    title: Text(
      "Confirm Book",
      textAlign: TextAlign.center,
    ),
    content: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.network(
          book.imageURL,
          height: 150,
        ),
        Divider(),
        rowInfo("Title", book.title),
        Divider(),
        rowInfoList("Author(s)", book.authors),
        Divider(),
        rowInfoList("Publisher(s)", book.publishers),
        rowInfo("Publish Date", book.publishDate),
        Divider(),
        rowInfo("Format", book.format),
        Divider(),
        confirmDenyButtons(onCancel, onConfirm)
      ],
    ),
  );
}

errorFindingBook(BuildContext context) {
  final snackBar = SnackBar(
    content: Text("Couldn't find this book"),
    duration: Duration(seconds: 3),
  );
  Scaffold.of(context).showSnackBar(snackBar);
}

class BarcodeScanner extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _BarcodeScannerState();
  }
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  String _scanBarcode = "";
  bool dialVisible = true;
  Future<List<PreBookData>> _getPreBook = getPreBooks();

  SpeedDial buildSpeedDial(BuildContext context) {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22.0),
      // child: Icon(Icons.add),
      onOpen: () => print('OPENING DIAL'),
      onClose: () => print('DIAL CLOSED'),
      visible: dialVisible,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: Icon(Icons.scanner, color: Colors.white),
          backgroundColor: Colors.deepOrange,
          onTap: () => scanBarcode(context),
          label: 'Barcode Scanner',
          labelStyle:
          TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          labelBackgroundColor: Colors.deepOrangeAccent,
        ),
        SpeedDialChild(
          child: Icon(Icons.edit, color: Colors.white),
          backgroundColor: Colors.green,
          onTap: () => print('SECOND CHILD'),
          label: 'Manually Add Book',
          labelStyle:
          TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          labelBackgroundColor: Colors.green,
        ),
        SpeedDialChild(
            child: Icon(Icons.input, color: Colors.white),
            backgroundColor: Colors.blue,
            onTap: () => getISBNNumber(context),
            label: "Manually Input ISBN Number",
            labelStyle:
            TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            labelBackgroundColor: Colors.blue)
      ],
    );
  }

  Future<void> searchBookByISBN(BuildContext context, String ISBN) async {
    final snackBar = SnackBar(
        content: Text("Looking for book..."), duration: Duration(seconds: 5));
    Scaffold.of(context).showSnackBar(snackBar);
    Book test = await searchOLByISBN(ISBN);
    Scaffold.of(context).removeCurrentSnackBar();

    if (test != null) {
      Function onCancel = () => Navigator.of(context).pop();
      Function onConfirm = () => {
        Navigator.of(context).pop()
        // TODO: What to do when the book is saved?
      };
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return confirmBookDialog(context, test, onCancel, onConfirm);
          });
    } else {
      errorFindingBook(context);
    }
  }

  checkScanAndSave(scanRes) async {
    Book test = await searchOLByISBN(scanRes);
    if (test != null) {
      await insertPreBook(PreBookData(test.title, test.imageURL, scanRes, 1));
    } else {
      await insertPreBook(PreBookData('UNK', 'UNK', 'UNK', 0));
    }
  }

  Future<void> scanBarcode(BuildContext context) async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    String barcodeScanRes;
    while (true) {
      try {
        barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
            "#ff6666", "Cancel", true, ScanMode.BARCODE);
        if (barcodeScanRes == "-1") {
          break;
        } else {
          if (!mounted) return;
          checkScanAndSave(barcodeScanRes);
        }
      } on PlatformException {
        // TODO: Better error handling here
        barcodeScanRes = 'Failed to get platform version.';
      }
    }
  }

  //
  Future<void> getISBNNumber(BuildContext context) {
    String isbnText = "";
    GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

    Function onCancel = () => Navigator.of(context).pop();
    Function onConfirm = () async {
      if (_formKey.currentState.validate()) {
        Navigator.pop(context);
        await searchBookByISBN(context, isbnText);
      }
    };
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("ISBN Number",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20)),
                  Divider(),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "Do not enter dashes or spaces",
                    ),
                    validator: (String newText) {
                      if (newText.length != 9 &&
                          newText.length != 10 &&
                          newText.length != 13) {
                        return "Must be length 9, 10, or 13";
                      } else if (newText.length == 13 &&
                          (newText.substring(0, 3) != "978" &&
                              newText.substring(0, 3) != "979")) {
                        return "First 3 digits should be 978 or 979";
                      } else {
                        return null;
                      }
                    },
                    onChanged: (String newText) {
                      isbnText = newText;
                    },
                  ),
                  confirmDenyButtons(onCancel, onConfirm)
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Builder(
          builder: (BuildContext context) => FutureBuilder(
            future: _getPreBook,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [CircularProgressIndicator()]);
              } else if (snapshot.data.isEmpty &&
                  snapshot.connectionState == ConnectionState.done) {
                return Text(
                    "Okay well there isn't anything here"); // TODO: Change
              } else {
                return ListView.builder(
                    itemCount: snapshot.data.length,
                    itemBuilder: (BuildContext context, int index) {
                      Widget currentIcon = snapshot.data[index].found == 0
                          ? Icon(Icons.close, color: Colors.red)
                          : Icon(Icons.check, color: Colors.green);
                      return Card(
                          child: ListTile(
                            title: Text(snapshot.data[index].title),
                            trailing: currentIcon,
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (BuildContext context) => BookForm(
                                          initializationData: snapshot.data[index])));
                            },
                          ));
                    });
              }
            },
          ),
        ),
        floatingActionButton: Builder(
            builder: (BuildContext context) => buildSpeedDial(context)));
  }
}
