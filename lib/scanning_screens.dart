import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:liber/api.dart';
import 'package:liber/local_database.dart';
import 'package:liber/verify_book.dart';

import 'add_book.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  bool dialVisible = true;
  Future<List<PreBookData>> _getPreBook = getPreBooks();

  SpeedDial buildSpeedDial(BuildContext context) {
    return SpeedDial(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22.0),
      onOpen: () => null,
      onClose: () => null,
      visible: dialVisible,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: Icon(Icons.scanner, color: Colors.white),
          backgroundColor: Colors.deepOrange,
          onTap: () => scanBarcode(context),
          label: 'Quick Scan',
          labelStyle:
          TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          labelBackgroundColor: Colors.deepOrangeAccent,
        ),
        SpeedDialChild(
          child: Icon(Icons.edit, color: Colors.white),
          backgroundColor: Colors.green,
          onTap: () => {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: Column(
                        mainAxisSize: MainAxisSize.min, children: [AddBook()]),
                  );
                })
          },
          label: 'Add Book',
          labelStyle:
          TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          labelBackgroundColor: Colors.green,
        ),
        SpeedDialChild(
            child: Icon(Icons.search, color: Colors.white),
            backgroundColor: Colors.blue,
            onTap: () => null,
            label: "Search Library",
            labelStyle:
            TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            labelBackgroundColor: Colors.blue)
      ],
    );
  }

  checkScanAndSave(scanRes) async {
    Book test = await searchOLByISBN(scanRes);
    if (test != null) {
      await insertPreBook(
          PreBookData(test.name, test.imageURL, scanRes, test.olID, 1));
    } else {
      await insertPreBook(PreBookData('UNK', 'UNK', 'UNK', 'UNK', 0));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Builder(
          builder: (BuildContext context) => RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _getPreBook = getPreBooks();
              });
            },
            child: FutureBuilder(
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
                        print(snapshot.data[index]);
                        return Card(
                            child: ListTile(
                              title: Text(snapshot.data[index].name),
                              trailing: currentIcon,
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (BuildContext context) => BookForm(
                                            initializationData:
                                            snapshot.data[index])));
                              },
                            ));
                      });
                }
              },
            ),
          ),
        ),
        floatingActionButton: Builder(
            builder: (BuildContext context) => buildSpeedDial(context)));
  }
}
