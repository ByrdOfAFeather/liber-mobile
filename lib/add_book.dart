import 'package:flutter/material.dart';
import 'package:liber/verify_book.dart';

import 'api.dart';
import 'local_database.dart';

String forceSmallString(String val) {
  if (val.length >= 15) {
    return "${val.substring(0, 12)}...";
  } else {
    return val;
  }
}

class FutureListView<T> extends StatefulWidget {
  final Function futureGetter;
  final Function tileBuilder;

  const FutureListView({Key key, this.futureGetter, this.tileBuilder})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FutureListView<T>();
  }
}

class _FutureListView<T> extends State<FutureListView> {
  Future<T> futureStore;

  @override
  void initState() {
    futureStore = widget.futureGetter();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget errorWidget = Center(
        child: Column(
          children: [
            Text("Unknown Error Occurred"),
            RaisedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Ok"),
            )
          ],
        ));

    return FutureBuilder(
      future: futureStore,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.hasError) {
            return errorWidget;
          } else if (snapshot.data == null &&
              snapshot.connectionState == ConnectionState.none) {
            return Container(); // This is the case where nothing has loaded yet
          } else if (snapshot.data != null) {
            return Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data.length,
                itemBuilder: (BuildContext context, int index) {
                  return widget.tileBuilder(context, snapshot.data[index]);
                },
              ),
            );
          } else {
            return errorWidget;
          }
        }
      },
    );
  }
}

class SelectBookFromWork extends StatefulWidget {
  final Work selectedWork;

  const SelectBookFromWork({Key key, this.selectedWork}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SelectBookFromWorkState();
  }
}

class _SelectBookFromWorkState extends State<SelectBookFromWork> {
  Future<List<Book>> associatedBooks;

  @override
  Widget build(BuildContext context) {
    Function tileBuilder = (BuildContext context, Book data) {
      return Card(
        child: ListTile(
          title: Column(
            children: [
              rowInfo("Title", data.name),
              rowInfoList(
                  "Publishers", data.publishers.map((e) => e.name).toList()),
              rowInfo("Date", data.publishDate)
            ],
          ),
          onTap: () {
            Function onConfirm = () {
              Navigator.pop(context, data);
            };
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return confirmBookDialog(context, data, onConfirm);
                }).then((value) {
              if (value == null) {
                return;
              }
              Navigator.pop(context, value);
            });
          },
        ),
      );
    };
    return FutureListView<List<Book>>(
      futureGetter: () => getBooksFromWork(widget.selectedWork),
      tileBuilder: tileBuilder,
    );
  }
}

Widget rowInfo(String label, String value) {
  if (value == null) {
    value = "Unknown";
  }
  if (value.length >= 20) {
    value = forceSmallString(value);
  }
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Expanded(child: Text("$label: ")), Text(value)],
  );
}

Widget rowInfoList(String label, List<String> values) {
  if (values.isEmpty) {
    values.add("Unknown");
  }
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(child: Text("$label: ")),
      Column(
        children: [
          ...values.map((String value) {
            value = forceSmallString(value);
            return Text(value);
          })
        ],
      )
    ],
  );
}

Widget confirmBookDialog(BuildContext context, Book book, Function onConfirm) {
  Widget bookImage = Container();
  if (book.imageURL != null) {
    bookImage = Image.network(book.imageURL, height: 150);
  }

  return AlertDialog(
    title: Text(
      "Confirm Book",
      textAlign: TextAlign.center,
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          bookImage,
          Divider(),
          rowInfo("Title", book.name),
          Divider(),
          rowInfoList("Author(s)", book.authors),
          Divider(),
          rowInfoList(
              "Publisher(s)", book.publishers.map((pub) => pub.name).toList()),
          rowInfo("Publish Date", book.publishDate),
          Divider(),
          rowInfo("Format", book.format),
          Divider(),
          confirmDenyButtons(onConfirm)
        ],
      ),
    ),
  );
}

Widget labeledIconButton(Icon icon, String labelText, Function onPressed) {
  return Expanded(
    child: FlatButton(
      onPressed: onPressed,
      child: Column(
        children: [
          icon,
          // IconButton(
          // icon: icon,
          // ),
          Text(labelText)
        ],
      ),
    ),
  );
}

Widget confirmDenyButtons(Function onConfirm) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      BackButton(color: Colors.red),
      IconButton(
          icon: Icon(Icons.check, color: Colors.green), onPressed: onConfirm)
    ],
  );
}

class SearchBook extends StatefulWidget {
  const SearchBook({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SearchBookState();
  }
}

class _SearchBookState extends State<SearchBook> {
  TextEditingController _controller = new TextEditingController();
  Future<List<Work>> bookSearchResult;

  @override
  void initState() {
    bookSearchResult = null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          ListTile(
            title: TextFormField(
              autofocus: true,
              controller: _controller,
              decoration: InputDecoration(labelText: "Search"),
              onEditingComplete: () {
                // TODO: Debouncing
                setState(() {
                  bookSearchResult = searchOLByName(_controller.text);
                });
              },
            ),
            trailing: Icon(Icons.search),
          ),
          Row(
            children: [
              Text("Search Results"),
              IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return SimpleDialog(children: [
                            Text(
                                "The following results are 'works,' they contain information "
                                    "about every book published under a specific name and author. As such "
                                    "there may be repeats, as well, you must first select a work and then select the specific book from that "
                                    "work. If the book you are looking for has an ISBN number it is highly recommended to use this instead.")
                          ]);
                        });
                  })
            ],
          ),
          Expanded(
              child: FutureBuilder(
                future: bookSearchResult,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState != ConnectionState.done &&
                      snapshot.connectionState != ConnectionState.none) {
                    return Center(child: CircularProgressIndicator());
                  } else {
                    if (snapshot.data == null &&
                        snapshot.connectionState == ConnectionState.none) {
                      return Container();
                    } else if (snapshot.data == null) {
                      return Center(child: Text("No results found"));
                    } else {
                      return Container(
                        width: double.maxFinite,
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: snapshot.data.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Card(
                                  child: ListTile(
                                    title: Text(
                                        "${snapshot.data[index].title}, ${snapshot.data[index].initialPublishDate}"),
                                    onTap: () {
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              content: SelectBookFromWork(
                                                  selectedWork:
                                                  snapshot.data[index] as Work),
                                            );
                                          }).then((value) async {
                                        if (value == null) {
                                          return;
                                        }
                                        Book val = value as Book;
                                        Navigator.of(context).pop();
                                        await insertPreBook(PreBookData(val.name,
                                            val.imageURL, val.isbn, val.olID, 1));
                                      });
                                    },
                                  ));
                            }),
                      );
                    }
                  }
                  return null;
                },
              ))
        ],
      ),
    );
  }
}

class GetISBNNumber extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GetISBNNumberState();
  }
}

class _GetISBNNumberState extends State<GetISBNNumber> {
  Widget searchingIndicator = Container();

  @override
  Widget build(BuildContext context) {
    String isbnText = "";
    GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
    Function onConfirm = () async {
      if (_formKey.currentState.validate()) {
        setState(() {
          searchingIndicator = CircularProgressIndicator();
        });
        Book bookRes;
        try {
          bookRes = await searchOLByISBN(isbnText);
          setState(() {
            searchingIndicator = Container();
          });
        } catch (e) {
          print("Caught an error here");
          print(e);
          setState(() {
            searchingIndicator = Text("Failed to get book");
          });
        }
        if (bookRes != null) {
          Navigator.of(context).pop();
          FocusManager.instance.primaryFocus.unfocus();
          showDialog(
              context: context,
              builder: (BuildContext context) {
                Function onConfirm = () async {
                  Navigator.of(context).pop();
                  await insertPreBook(PreBookData(bookRes.name,
                      bookRes.imageURL, isbnText, bookRes.olID, 1));
                };
                return confirmBookDialog(context, bookRes, onConfirm);
              });
        } else {
          searchingIndicator = Text("Couldn't find book");
        }
      }
    };

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: TextFormField(
              autofocus: true,
              decoration: InputDecoration(
                  hintText: "Do not enter dashes or spaces",
                  labelText: "ISBN #"),
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
          ),
          confirmDenyButtons(onConfirm),
          searchingIndicator
        ],
      ),
    );
  }
}

class WorksScreen extends StatefulWidget {
  Work workInfo;

  @override
  State<StatefulWidget> createState() {
    return _WorksScreenState();
  }
}

class _WorksScreenState extends State<WorksScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("${widget.workInfo.title}"),
        // PaginationWidget(futureGetter: , onSelect: ,)
      ],
    );
  }
}

class AddBook extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AddBookState();
  }
}

enum AddBookState { selection, byISBN, byName, manually }

class _AddBookState extends State<AddBook> {
  AddBookState currentState = AddBookState.selection;

  @override
  Widget build(BuildContext context) {
    Widget currentWidget;

    if (currentState == AddBookState.selection) {
      currentWidget = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          labeledIconButton(
              Icon(
                Icons.input,
                size: 40,
              ),
              "By ISBN", () {
            setState(() {
              currentState = AddBookState.byISBN;
            });
          }),
          labeledIconButton(Icon(Icons.auto_stories, size: 40), "By Title", () {
            setState(() {
              currentState = AddBookState.byName;
            });
          }),
          labeledIconButton(Icon(Icons.add, size: 40), "Manual", () {
            setState(() {
              currentState = AddBookState.manually;
            });
          })
        ],
      );
    } else if (currentState == AddBookState.byISBN) {
      currentWidget = GetISBNNumber();
    } else if (currentState == AddBookState.byName) {
      currentWidget = SearchBook();
    } else if (currentState == AddBookState.manually) {
      // TODO: this one is a bit different
    }

    return WillPopScope(
        child: currentWidget,
        onWillPop: () async {
          if (currentState != AddBookState.selection) {
            setState(() {
              currentState = AddBookState.selection;
            });
            return false;
          } else {
            return true;
          }
        });
  }
}
