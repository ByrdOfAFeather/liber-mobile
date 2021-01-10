import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liber/local_database.dart';

import 'api.dart';

class PaginationWidget<T extends NamedEntity> extends StatefulWidget {
  // This can be used for authors or publishers or even
  // books when viewing from the author/publisher perspective
  final Function futureGetterPagination;
  final Function futureGetterSearch;
  final Function onSelect;

  const PaginationWidget(
      {Key key,
        this.futureGetterPagination,
        this.onSelect,
        this.futureGetterSearch})
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
  bool searchMode = false;
  TextEditingController _searchController;

  @override
  void initState() {
    _searchController = TextEditingController();
    future = widget.futureGetterPagination(paginationIndex);
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              if (paginationIndex != 0 && !searchMode) {
                upButton = IconButton(
                    icon: Icon(Icons.arrow_upward),
                    onPressed: () {
                      setState(() {
                        if (paginationIndex == 0) {
                          return;
                        } else {
                          paginationIndex -= 10;
                          future =
                              widget.futureGetterPagination(paginationIndex);
                        }
                      });
                    });
              } else {
                upButton = Container();
              }

              if (snapshot.data["end_of_pagination"] != true && !searchMode) {
                downButton = IconButton(
                    icon: Icon(Icons.arrow_downward),
                    onPressed: () {
                      setState(() {
                        paginationIndex += 10;
                        future = widget.futureGetterPagination(paginationIndex);
                      });
                    });
              } else {
                downButton = Container();
              }

              List<T> pagination = snapshot.data["result"];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: TextFormField(
                      controller: _searchController,
                      onEditingComplete: () {
                        if (_searchController.text.isNotEmpty) {
                          setState(() {
                            searchMode = true;
                            future = widget
                                .futureGetterSearch(_searchController.text);
                          });
                        } else {
                          setState(() {
                            searchMode = false;
                            future =
                                widget.futureGetterPagination(paginationIndex);
                          });
                        }
                      },
                      decoration: InputDecoration(hintText: "Search"),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          setState(() {
                            searchMode = true;
                            future = widget
                                .futureGetterSearch(_searchController.text);
                          });
                        } else {
                          setState(() {
                            searchMode = false;
                            future =
                                widget.futureGetterPagination(paginationIndex);
                          });
                        }
                      },
                    ),
                  ),
                  upButton,
                  Expanded(
                    child: pagination.length != 0
                        ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: pagination.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Card(
                            child: ListTile(
                              trailing: Icon(Icons.check),
                              title: Text(pagination[index].name),
                              onTap: () =>
                                  widget.onSelect(pagination[index]),
                            ),
                          );
                        })
                        : Center(child: Text("No Results Found")),
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

class _NamedEntitySelect<T extends NamedEntity> extends StatefulWidget {
  final T initNamedEntity;
  final Function paginationGetter;
  final Function searchGetter;
  final Function onDelete;
  final Function onSelect;
  final String title;

  const _NamedEntitySelect(
      {Key key,
        this.initNamedEntity,
        this.onDelete,
        this.paginationGetter,
        this.onSelect,
        this.title,
        this.searchGetter})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NamedEntitySelectionState<T>();
  }
}

class _NamedEntitySelectionState<T extends NamedEntity>
    extends State<_NamedEntitySelect> {
  T selectedEntity;
  String cardText;

  @override
  void initState() {
    selectedEntity = widget.initNamedEntity;
    cardText = selectedEntity?.name;
    cardText ??= "Unselected";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => widget.onDelete(selectedEntity)),
        onTap: () async {
          var futureEntity = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(widget.title),
                  content: PaginationWidget(
                    futureGetterSearch: widget.searchGetter,
                    futureGetterPagination: widget.paginationGetter,
                    onSelect: (NamedEntity newSelectedEntity) {
                      widget.onSelect(newSelectedEntity);
                      Navigator.of(context).pop(newSelectedEntity);
                    },
                  ),
                );
              });
          if (futureEntity != null) {
            setState(() {
              selectedEntity = futureEntity as T;
              cardText = selectedEntity.name;
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
  LeatherBound,
  TurtleBack,
  AudioBookUnabridged,
  AudioBookAbridged,
  Unknown
}

const Map<PhysicalFormats, String> physicalFormatToString = {
  PhysicalFormats.Hardcover: "Hardcover",
  PhysicalFormats.Paperback: "Paperback",
  PhysicalFormats.MassMarketPaperBack: "Mass-Market Paperback",
  PhysicalFormats.LibraryBinding: "Library Binding",
  PhysicalFormats.SpiralBinding: "Spiral Binding",
  PhysicalFormats.LeatherBound: "Leather Bound",
  PhysicalFormats.TurtleBack: "Turtleback",
  PhysicalFormats.Unknown: "Unknown",
  // TODO: Perhaps at some point audio books are important, not now
};

const Map<PhysicalFormats, String> physicalFormatToApiString = {
  PhysicalFormats.Hardcover: "HARDCOVER",
  PhysicalFormats.Paperback: "SOFTCOVER",
  PhysicalFormats.MassMarketPaperBack: "MASSMARKETPAPERBACK",
  PhysicalFormats.LibraryBinding: "LIBRARYBINDING",
  PhysicalFormats.SpiralBinding: "SPIRALBINDING",
  PhysicalFormats.LeatherBound: "LEATHERBOUND",
  PhysicalFormats.TurtleBack: "TURTLEBACK",
  PhysicalFormats.Unknown: "UNKNOWN",
  // TODO: Perhaps at some point audio books are important, not now
};

const Map<String, PhysicalFormats> stringToPhysicalFormat = {
  "paperback": PhysicalFormats.Paperback,
  "library binding": PhysicalFormats.LibraryBinding,
  "mass market paperback": PhysicalFormats.MassMarketPaperBack,
  "mass-market-paperback": PhysicalFormats.MassMarketPaperBack,
  "hardcover": PhysicalFormats.Hardcover,
  "leather-bound": PhysicalFormats.LeatherBound,
  "turtleback": PhysicalFormats.TurtleBack,
};

class _FormatSelectorState extends State<_FormatSelector> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select Format"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}

class FormatSelectorField extends FormField<String> {
  FormatSelectorField({
    FormFieldSetter<String> onSaved,
    FormFieldValidator<String> validator,
    String initialValue = "Select format",
  }) : super(
      onSaved: onSaved,
      validator: validator,
      initialValue: initialValue,
      builder: (FormFieldState<String> state) {
        return Column(
          children: [
            Text("Select Physical format"),
            Card(
              child: ListTile(
                  title: Text(state.value),
                  onTap: () {
                    showDialog(
                        context: state.context,
                        builder: (BuildContext context) =>
                            _FormatSelector()).then((value) {
                      if (value != null) {
                        state.didChange(physicalFormatToString[value]);
                        state.save();
                      }
                    });
                  }),
            )
          ],
        );
      });
}

class _BookInfo extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController isbnController;
  final PhysicalFormats selectedFormat;
  final FormatSelectorField formatSelector;

  const _BookInfo(
      {Key key,
        this.titleController,
        this.isbnController,
        this.selectedFormat,
        this.formatSelector})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BookInfoState();
  }
}

class _BookInfoState extends State<_BookInfo> {
  IconData currentDisplayStateIcon = Icons.arrow_upward;
  bool displaying = true;
  String formatValue;
  String titleValue;
  String isbnValue;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.titleController.dispose();
    widget.isbnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          ListTile(
            title: Text(
              "Book Info",
              style: TextStyle(fontSize: 22),
            ),
            trailing: IconButton(
              icon: Icon(currentDisplayStateIcon),
              onPressed: () {
                if (currentDisplayStateIcon == Icons.arrow_upward) {
                  setState(() {
                    currentDisplayStateIcon = Icons.arrow_downward;
                    displaying = false;
                  });
                } else {
                  setState(() {
                    currentDisplayStateIcon = Icons.arrow_upward;
                    displaying = true;
                  });
                }
              },
            ),
          ),
          Divider(),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: displaying
                ? Column(
              children: [
                ListTile(
                  title: TextFormField(
                    controller: widget.titleController,
                    decoration: InputDecoration(labelText: "Title"),
                    onEditingComplete: () {
                      titleValue = widget.titleController.text;
                      FocusScope.of(context).unfocus();
                    },
                    validator: (String validTest) {
                      if (validTest.isEmpty) {
                        return "The book must have a title!";
                      } else {
                        return null;
                      }
                    },
                  ),
                ),
                ListTile(
                  title: TextFormField(
                      controller: widget.isbnController,
                      decoration: InputDecoration(labelText: "ISBN #"),
                      onEditingComplete: () {
                        isbnValue = widget.isbnController.text;
                        FocusScope.of(context).unfocus();
                      }),
                ),
                Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: widget.formatSelector)
              ],
            )
                : Container(),
          )
        ],
      ),
    );
  }
}

class _PublisherInfo extends StatefulWidget {
  final TextEditingController publishDateController;
  final List<IDEntity> publishers;

  const _PublisherInfo({Key key, this.publishDateController, this.publishers})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PublisherInfoState();
  }
}

class _PublisherInfoState extends State<_PublisherInfo>
    with SingleTickerProviderStateMixin {
  IconData currentDisplayStateIcon = Icons.arrow_upward;
  bool displaying = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text("Publisher Info", style: TextStyle(fontSize: 22)),
          trailing: IconButton(
            icon: Icon(currentDisplayStateIcon),
            onPressed: () {
              if (currentDisplayStateIcon == Icons.arrow_upward) {
                setState(() {
                  currentDisplayStateIcon = Icons.arrow_downward;
                  displaying = false;
                });
              } else {
                setState(() {
                  currentDisplayStateIcon = Icons.arrow_upward;
                  displaying = true;
                });
              }
            },
          ),
        ),
        Divider(),
        AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: displaying
                ? Column(
              children: [
                ...widget.publishers
                    .asMap()
                    .entries
                    .map((publisherEntry) {
                  IDEntity publisher = publisherEntry.value;
                  int index = publisherEntry.key;
                  return _NamedEntitySelect<IDEntity>(
                    paginationGetter: getPublishersPagination,
                    searchGetter: searchPublishers,
                    initNamedEntity: publisher,
                    title: "Select Publisher",
                    onSelect: (IDEntity toChange) {
                      widget.publishers[index] = toChange;
                    },
                    onDelete: (IDEntity toRemove) {
                      setState(() {
                        widget.publishers.removeWhere(
                                (IDEntity pub) => pub.id == toRemove.id);
                      });
                    },
                  );
                }),
                IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () async {
                      var futurePublisher = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Select Publisher to Add"),
                              content: PaginationWidget(
                                futureGetterSearch: searchPublishers,
                                futureGetterPagination:
                                getPublishersPagination,
                                onSelect:
                                    (IDEntity newSelectedPublisher) {
                                  Navigator.of(context)
                                      .pop(newSelectedPublisher);
                                },
                              ),
                            );
                          });
                      if (futurePublisher != null) {
                        setState(() {
                          if (!widget.publishers
                              .contains(futurePublisher)) {
                            widget.publishers.add(futurePublisher);
                          }
                        });
                      }
                    }),
                ListTile(
                  title: TextFormField(
                    controller: widget.publishDateController,
                    decoration:
                    InputDecoration(labelText: "Publish Date"),
                  ),
                ),
              ],
            )
                : Container())
      ],
    );
  }
}

class _AuthorInfo extends StatefulWidget {
  final List<IDEntity> authors;

  const _AuthorInfo({Key key, this.authors}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AuthorInfoState();
  }
}

class _AuthorInfoState extends State<_AuthorInfo> {
  IconData currentDisplayStateIcon = Icons.arrow_upward;
  bool displaying = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text("Author Info", style: TextStyle(fontSize: 22)),
          trailing: IconButton(
            icon: Icon(currentDisplayStateIcon),
            onPressed: () {
              if (currentDisplayStateIcon == Icons.arrow_upward) {
                setState(() {
                  currentDisplayStateIcon = Icons.arrow_downward;
                  displaying = false;
                });
              } else {
                setState(() {
                  currentDisplayStateIcon = Icons.arrow_upward;
                  displaying = true;
                });
              }
            },
          ),
        ),
        Divider(),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: displaying
              ? Column(
            children: [
              ...widget.authors.asMap().entries.map((authorEntry) {
                IDEntity author = authorEntry.value;
                int index = authorEntry.key;
                return _NamedEntitySelect<IDEntity>(
                  title: "Select Author",
                  searchGetter: searchAuthors,
                  paginationGetter: getAuthorsPagination,
                  initNamedEntity: author,
                  onSelect: (IDEntity toChange) {
                    setState(() {
                      widget.authors[index] = toChange;
                    });
                  },
                  onDelete: (IDEntity toRemove) {
                    setState(() {
                      widget.authors.removeWhere(
                              (IDEntity pub) => pub.id == toRemove.id);
                    });
                  },
                );
              }),
              // TODO: This is more repeat code
              IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () async {
                    var futureAuthor = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Select Author to Add"),
                            content: PaginationWidget(
                              futureGetterPagination:
                              getAuthorsPagination,
                              onSelect: (IDEntity newSelectedAuthor) {
                                Navigator.of(context)
                                    .pop(newSelectedAuthor);
                              },
                            ),
                          );
                        });
                    if (futureAuthor != null) {
                      setState(() {
                        if (widget.authors
                            .where((IDEntity author) =>
                        author.id == futureAuthor.id)
                            .isEmpty) {
                          widget.authors.add(futureAuthor);
                        }
                      });
                    }
                  }),
            ],
          )
              : Container(),
        )
      ],
    );
  }
}

class _BookForm extends StatefulWidget {
  final Book initData;
  final int localBookID;

  const _BookForm({Key key, this.initData, this.localBookID}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BookFormState();
  }
}

class _BookFormState extends State<_BookForm> {
  GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  String formatValue;

  // Book info setup
  TextEditingController titleController;
  TextEditingController isbnController;
  PhysicalFormats selectedFormat;

  // Publish info setup
  List<IDEntity> publishers;
  TextEditingController publishDateController;

  // Author info setup
  List<IDEntity> authors;

  @override
  void initState() {
    titleController = TextEditingController(text: widget.initData?.name);
    isbnController = TextEditingController(text: widget.initData?.isbn);

    selectedFormat =
    stringToPhysicalFormat[widget.initData?.format?.toLowerCase()];
    selectedFormat ??= PhysicalFormats.Unknown;
    formatValue = physicalFormatToString[selectedFormat];

    publishers = widget.initData?.publishers;
    publishers ??= [];
    publishDateController =
        TextEditingController(text: widget.initData?.publishDate);

    authors = widget.initData?.authors;
    authors ??= [];

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initData == null) {
      return Text("The data is null");
    }

    try {
      widget.initData.format = physicalFormatToString[
      stringToPhysicalFormat[widget.initData.format.toLowerCase()]];
    } catch (error) {
      widget.initData.format = "Select Format";
    }

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

    FormatSelectorField formatSelector = FormatSelectorField(
      onSaved: (String newFormat) {
        setState(() {
          formatValue = newFormat;
          selectedFormat = stringToPhysicalFormat[newFormat];
        });
      },
      initialValue: formatValue,
    );

    return Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              bookCover,
              _BookInfo(
                titleController: titleController,
                isbnController: isbnController,
                formatSelector: formatSelector,
              ),
              _PublisherInfo(
                publishDateController: publishDateController,
                publishers: publishers,
              ),
              _AuthorInfo(authors: authors),
              RaisedButton(
                child: Text("Verify"),
                color: Colors.green,
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    SnackBar addBookScaffold = SnackBar(
                      content: Text("Adding Book"),
                    );
                    Scaffold.of(context).showSnackBar(addBookScaffold);

                    Map<String, dynamic> bookData = {
                      "authors": IDEntityListToMap(authors),
                      "publishers": IDEntityListToMap(publishers),
                      "publish_date": publishDateController.text,
                      "title": titleController.text,
                      "isbn": isbnController.text,
                      "physical_format":
                      physicalFormatToApiString[selectedFormat]
                    };

                    Map<String, dynamic> bookRes = await saveBook(bookData);
                    if (bookRes["status_code"] == 200) {
                      await deletePreBook(widget.localBookID);
                      Navigator.of(context).pop();
                    } else {
                      Scaffold.of(context).removeCurrentSnackBar();
                      SnackBar failedToAddScaffold = SnackBar(
                        content: Text("Failed to add book, please report this"),
                        duration: Duration(seconds: 2),
                      );
                      Scaffold.of(context).showSnackBar(failedToAddScaffold);
                    }
                  }
                },
              )
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
    return BookFormState();
  }
}

class BookFormState extends State<BookForm> {
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
                  return _BookForm();
                } else {
                  return _BookForm(
                      initData: snapshot.data,
                      localBookID: widget.initializationData.id);
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
