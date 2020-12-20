import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liber/local_database.dart';

import 'api.dart';

Function blueBackgroundWhiteAccent = (String labelText) => InputDecoration(
  labelText: labelText,
  labelStyle: TextStyle(color: Colors.white),
  enabledBorder: UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.white),
  ),
  focusedBorder: UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.black),
  ),
  border: UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.white),
  ),
);

class PaginationWidget<T extends NamedEntity> extends StatefulWidget {
  // This can be used for authors or publishers or even
  // books when viewing from the author/publisher perspective
  final Function futureGetter;
  final Function onSelect;

  const PaginationWidget({Key key, this.futureGetter, this.onSelect})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PaginationWidgetState<T>();
  }
}

class _PaginationWidgetState<T extends NamedEntity>
    extends State<PaginationWidget> {
  Future<Map<String, dynamic>> future;
  int paginationIndex = 0;

  @override
  void initState() {
    future = widget.futureGetter(paginationIndex);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      child: FutureBuilder(
        future: future,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.hasData && snapshot.data != null) {
              Widget downButton;
              Widget upButton;
              if (paginationIndex != 0) {
                upButton = IconButton(
                    icon: Icon(Icons.arrow_upward),
                    onPressed: () {
                      setState(() {
                        if (paginationIndex == 0) {
                          return;
                        } else {
                          paginationIndex -= 10;
                          future = widget.futureGetter(paginationIndex);
                        }
                      });
                    });
              } else {
                upButton = Container();
              }

              if (snapshot.data["end_of_pagination"] != true) {
                downButton = IconButton(
                    icon: Icon(Icons.arrow_downward),
                    onPressed: () {
                      setState(() {
                        paginationIndex += 10;
                        future = widget.futureGetter(paginationIndex);
                      });
                    });
              } else {
                downButton = Container();
              }

              List<T> pagination = snapshot.data["result"];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  upButton,
                  Expanded(
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: pagination.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Card(
                            child: ListTile(
                              trailing: Icon(Icons.check),
                              title: Text(pagination[index].name),
                              onTap: () => widget.onSelect(pagination[index]),
                            ),
                          );
                        }),
                  ),
                  downButton
                ],
              );
            } else {
              return Text("Connection Failed.");
            }
          }
        },
      ),
    );
  }
}

class _PublisherSelect extends StatefulWidget {
  final Publisher initPublisher;
  final Function onDelete;

  const _PublisherSelect({Key key, this.initPublisher, this.onDelete})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PublisherSelectState();
  }
}

class _PublisherSelectState extends State<_PublisherSelect> {
  Publisher selectedPublisher;
  String cardText;

  @override
  void initState() {
    selectedPublisher = widget.initPublisher;
    cardText = selectedPublisher?.name;
    cardText ??= "Unselected";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => widget.onDelete(selectedPublisher)),
        onTap: () async {
          var futurePublisher = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  content: PaginationWidget(
                    futureGetter: getPublishersPagination,
                    onSelect: (Publisher newSelectedPublisher) {
                      print(newSelectedPublisher);
                      Navigator.of(context).pop(newSelectedPublisher);
                    },
                  ),
                );
              });
          if (futurePublisher != null) {
            setState(() {
              print(futurePublisher.name);
              selectedPublisher = futurePublisher as Publisher;
              cardText = selectedPublisher.name;
            });
          }
        },
        title: Text(cardText),
      ),
    );
  }
}

class _FormatSelector extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FormatSelectorState();
  }
}

enum PhysicalFormats {
  Hardcover,
  Paperback,
  MassMarketPaperBack,
  LibraryBinding,
  SpiralBinding,
  AudioBookUnabridged,
  AudioBookAbridged
}

const Map<PhysicalFormats, String> physicalFormatToString = {
  PhysicalFormats.Hardcover: "Hardcover",
  PhysicalFormats.Paperback: "Paperback",
  PhysicalFormats.MassMarketPaperBack: "Mass-Market Paperback",
  PhysicalFormats.LibraryBinding: "Library Binding",
  PhysicalFormats.SpiralBinding: "Spiral Binding",
  // TODO: Perhaps at some point audio books are important, not now
};

class _FormatSelectorState extends State<_FormatSelector> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select Format"),
      content: Column(
        children: [
          ...physicalFormatToString.keys.map((e) {
            return Card(
                child: ListTile(
                  title: Text(physicalFormatToString[e]),
                  onTap: () {
                    Navigator.pop(context, e);
                  },
                ));
          }).toList()
        ],
      ),
    );
  }
}

class BookInfoForm extends StatefulWidget {
  final Book initData;

  const BookInfoForm({Key key, this.initData}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BookInfoForm();
  }
}

class _BookInfoForm extends State<BookInfoForm> {
  List<Publisher> selectedPublishers;
  GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  @override
  void initState() {
    selectedPublishers = widget.initData?.publishers;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initData == null) {
      return Text("The data is null");
    }

    Widget physicalFormatInput;
    widget.initData.format ??= "Select Format";
    physicalFormatInput = Card(
      child: ListTile(
          title: Text(widget.initData.format),
          onTap: () {
            showDialog(
                context: context,
                builder: (BuildContext context) => _FormatSelector())
                .then((value) {
              if (value != null) {
                setState(() {
                  widget.initData.format = physicalFormatToString[value];
                });
              }
            });
          }),
    );

    Widget bookCover = Container();
    if (widget.initData.imageURL != null) {
      bookCover = Center(
        child: Image.network(widget.initData.imageURL, frameBuilder:
            (BuildContext context, Widget child, int frame,
            bool wasSyncLoaded) {
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
      );
    }

    return Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              bookCover,
              Container(
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20, top: 20),
                  child: Column(
                    children: [
                      Text(
                        "Book Info",
                        style: TextStyle(fontSize: 22, color: Colors.white),
                      ),
                      Divider(
                        color: Colors.white,
                      ),
                      ListTile(
                        title: TextFormField(
                            initialValue: widget.initData.name,
                            cursorColor: Colors.white,
                            style: TextStyle(color: Colors.white),
                            decoration: blueBackgroundWhiteAccent("Title")),
                      ),
                      ListTile(
                        title: TextFormField(
                          initialValue: widget.initData.isbn,
                          cursorColor: Colors.white,
                          style: TextStyle(color: Colors.white),
                          decoration: blueBackgroundWhiteAccent("ISBN #"),
                        ),
                      ),
                      physicalFormatInput,
                    ],
                  ),
                ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 20),
                  child: Column(
                    children: [
                      Text("Publisher Info", style: TextStyle(fontSize: 22)),
                      Divider(),
                      ...widget.initData.publishers
                          .map((Publisher publisher) => _PublisherSelect(
                        initPublisher: publisher,
                        onDelete: (Publisher toRemove) {
                          setState(() {
                            widget.initData.publishers.removeWhere(
                                    (Publisher pub) =>
                                pub.id == toRemove.id);
                          });
                        },
                      )),
                      IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () async {
                            var futurePublisher = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: PaginationWidget(
                                      futureGetter: getPublishersPagination,
                                      onSelect:
                                          (Publisher newSelectedPublisher) {
                                        Navigator.of(context)
                                            .pop(newSelectedPublisher);
                                      },
                                    ),
                                  );
                                });
                            if (futurePublisher != null) {
                              setState(() {
                                widget.initData.publishers.add(futurePublisher);
                              });
                            }
                          }),
                      ListTile(
                        title: TextFormField(
                          initialValue: widget.initData.publishDate,
                          decoration:
                          InputDecoration(labelText: "Publish Date"),
                        ),
                      ),
                    ],
                  )),
              // ),
              Divider(
                thickness: 2,
              ),
              ListTile(
                  title: TextFormField(
                    initialValue: widget.initData.authors[0],
                  )),
            ],
          ),
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
      bookData = searchOLByOLID(widget.initializationData.olID);
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
                return Text("ERROR");
              }
            }),
      );
    }
    return null;
  }
}
