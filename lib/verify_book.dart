import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liber/local_database.dart';

import 'api.dart';

class BookInfoForm extends StatefulWidget {
  final Book initData;

  const BookInfoForm({Key key, this.initData}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BookInfoForm();
  }
}

class _BookInfoForm extends State<BookInfoForm> {
  bool _isSoftback = false;
  bool _isHardback = false;
  GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  @override
  void initState() {
    _isSoftback = widget.initData.format == "softback";
    _isHardback = widget.initData.format == "hardback";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initData == null) {
      print("Oops I got here");
      return Text("Bruh");
    }

    Widget physicalFormatInput;
    if (widget.initData.format != null) {
      physicalFormatInput = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ChoiceChip(
            label: Text("Hardback"),
            labelStyle: TextStyle(color: Colors.white),
            selected: _isHardback,
            onSelected: (bool newInput) => {
              setState(() {
                _isHardback = !_isHardback;
                if (_isSoftback) {
                  _isSoftback = !_isSoftback;
                }
              })
            },
            selectedColor: Colors.blue,
            backgroundColor: Colors.red,
          ),
          Text("Or"),
          ChoiceChip(
            label: Text("Softback"),
            labelStyle: TextStyle(color: Colors.white),
            selected: _isSoftback,
            onSelected: (bool newInput) => {
              setState(() {
                _isSoftback = !_isSoftback;
                if (_isHardback) {
                  _isHardback = !_isHardback;
                }
                print(_isSoftback);
              })
            },
            selectedColor: Colors.blue,
            backgroundColor: Colors.red,
          )
        ],
      );
    } else {
      physicalFormatInput = Container();
    }

    return Form(
        key: _formKey,
        child: Column(
          children: [
            Center(
              child: Image.network(widget.initData.imageURL, frameBuilder: (BuildContext context, Widget child, int frame, bool wasSyncLoaded) {
                if (wasSyncLoaded) {
                  return child;
                }
                return AnimatedOpacity(
                  child: child,
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOut,
                );
              }),
            ),
            ListTile(
              title: TextFormField(
                  initialValue: widget.initData.title,
                  decoration: InputDecoration(labelText: "Book Title")),
            ),
            ListTile(
              title: TextFormField(
                initialValue: widget.initData.publishDate,
                decoration: InputDecoration(labelText: "Publish Date"),
              ),
            ),
            ListTile(
              title: TextFormField(
                initialValue: widget.initData.isbn,
                decoration: InputDecoration(
                  labelText: "ISBN Number",
                ),
              ),
            ),
            ListTile(
              title: TextFormField(
                initialValue: widget.initData.authors[0],
              )
            ),
            physicalFormatInput,
          ],
        ));
  }
}

class BookForm extends StatefulWidget {
  final PreBookData initializationData;

  const BookForm({Key key, this.initializationData}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BookFormState();
  }
}

class _BookFormState extends State<BookForm> {
  Future<Book> bookData;

  @override
  void initState() {
    if (widget.initializationData.found == 1) {
      bookData = searchOLByISBN(widget.initializationData.ISBN);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initializationData.found == 1) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Add Book"),
        ),
        body: FutureBuilder(
            future: bookData,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.data == null) {
                  return BookInfoForm();
                } else {
                  return BookInfoForm(initData: snapshot.data);
                }
              } else {
                print(snapshot);
                print(snapshot.connectionState);
                print(snapshot.data);
                return Text("ERROR");
              }
            }),
      );
    }
    return null;
  }
}
