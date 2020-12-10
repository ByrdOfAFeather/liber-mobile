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
  GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    if (widget.initData == null) {
      print("Oops I got here");
      return Text("Bruh");
    }
    return Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Image.network(widget.initData.imageURL),
            ),
            TextFormField(
                initialValue: widget.initData.title,
                decoration: InputDecoration(
                    labelText: "Book Title"
                )),
            TextFormField(
              initialValue: widget.initData.publishDate,
              decoration: InputDecoration(
                  labelText: "Publish Date"
              ),
            ),
          ],
        )
    );
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
        body: FutureBuilder(
            future: bookData,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
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
            }
        ),
      );
    }
    return null;
  }
}