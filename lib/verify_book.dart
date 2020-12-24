import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liber/local_database.dart';

import 'api.dart';

class PaginationWidget<T extends NamedEntity> extends StatefulWidget {
  // This can be used for authors or publishers or even
  // books when viewing from the author/publisher perspective
  final Function futureGetter;
  final Function onSelect;

  const PaginationWidget({Key key, this.futureGetter, this.onSelect}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PaginationWidgetState<T>();
  }
}

class _PaginationWidgetState<T extends NamedEntity> extends State<PaginationWidget> {
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

class _NamedEntitySelect<T extends NamedEntity> extends StatefulWidget {
  final T initNamedEntity;
  final Function onDelete;
  final Function paginationGetter;
  final Function onSelect;

  const _NamedEntitySelect({Key key, this.initNamedEntity, this.onDelete, this.paginationGetter, this.onSelect})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NamedEntitySelectionState<T>();
  }
}

class _NamedEntitySelectionState<T extends NamedEntity> extends State<_NamedEntitySelect> {
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
        trailing: IconButton(icon: Icon(Icons.delete), onPressed: () => widget.onDelete(selectedEntity)),
        onTap: () async {
          var futureEntity = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  content: PaginationWidget(
                    futureGetter: widget.paginationGetter,
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
        return Card(
          child: ListTile(
              title: Text(state.value),
              onTap: () {
                showDialog(context: state.context, builder: (BuildContext context) => _FormatSelector())
                    .then((value) {
                  if (value != null) {
                    state.didChange(physicalFormatToString[value]);
                    state.save();
                  }
                });
              }),
        );
      });
}

class _BookInfo extends StatefulWidget {
  final Book initData;

  const _BookInfo({Key key, this.initData}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BookInfoState();
  }
}

class _BookInfoState extends State<_BookInfo> {
  TextEditingController _titleController;
  TextEditingController _isbnController;
  IconData currentDisplayStateIcon = Icons.arrow_upward;
  bool displaying = true;
  String formatValue;
  String titleValue;
  String isbnValue;

  @override
  void initState() {
    _titleController = TextEditingController(text: widget.initData.name);
    _isbnController =  TextEditingController(text: widget.initData.isbn);
    formatValue = widget.initData.format;
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
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
                    controller: _titleController,
                    decoration: InputDecoration(labelText: "Title"),
                    onEditingComplete: () {
                      titleValue = _titleController.text;
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                ListTile(
                  title: TextFormField(
                      controller: _isbnController,
                      decoration: InputDecoration(labelText: "ISBN #"),
                      onEditingComplete: () {
                        isbnValue = _isbnController.text;
                        FocusScope.of(context).unfocus();
                      }),
                ),
                FormatSelectorField(
                  onSaved: (String newFormat) {
                    formatValue = newFormat;
                  },
                  initialValue: formatValue,
                )
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
  final Book initData;

  const _PublisherInfo({Key key, this.initData}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PublisherInfoState();
  }
}

class _PublisherInfoState extends State<_PublisherInfo> with SingleTickerProviderStateMixin {
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
                ...widget.initData.publishers.asMap().entries.map((publisherEntry) {
                  IDEntity publisher = publisherEntry.value;
                  int index = publisherEntry.key;
                  return _NamedEntitySelect<IDEntity>(
                    paginationGetter: getPublishersPagination,
                    initNamedEntity: publisher,
                    onSelect: (IDEntity toChange) {
                      widget.initData.publishers[index] = toChange;
                    },
                    onDelete: (IDEntity toRemove) {
                      setState(() {
                        widget.initData.publishers.removeWhere((IDEntity pub) => pub.id == toRemove.id);
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
                              content: PaginationWidget(
                                futureGetter: getPublishersPagination,
                                onSelect: (IDEntity newSelectedPublisher) {
                                  Navigator.of(context).pop(newSelectedPublisher);
                                },
                              ),
                            );
                          });
                      if (futurePublisher != null) {
                        setState(() {
                          if (!widget.initData.publishers.contains(futurePublisher)) {
                            widget.initData.publishers.add(futurePublisher);
                          }
                        });
                      }
                    }),
                ListTile(
                  title: TextFormField(
                    initialValue: widget.initData.publishDate,
                    decoration: InputDecoration(labelText: "Publish Date"),
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
  final Book initData;

  const _AuthorInfo({Key key, this.initData}) : super(key: key);

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
              ...widget.initData.authors.asMap().entries.map((authorEntry) {
                Author author = authorEntry.value;
                int index = authorEntry.key;
                return _NamedEntitySelect<Author>(
                  paginationGetter: getAuthorsPagination,
                  initNamedEntity: author,
                  onSelect: (Author toChange) {
                    widget.initData.authors[index] = toChange;
                  },
                  onDelete: (Author toRemove) {
                    setState(() {
                      widget.initData.authors.removeWhere((Author pub) => pub.olID == toRemove.olID);
                    });
                  },
                );
              })
            ],
          )
              : Container(),
        )
      ],
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
  List<IDEntity> selectedPublishers;
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
            showDialog(context: context, builder: (BuildContext context) => _FormatSelector()).then((value) {
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
        child: Image.network(widget.initData.imageURL,
            frameBuilder: (BuildContext context, Widget child, int frame, bool wasSyncLoaded) {
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
              _BookInfo(
                initData: widget.initData,
              ),
              _PublisherInfo(initData: widget.initData),
              _AuthorInfo(initData: widget.initData)
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

/*
Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 20),
                  child: Column(
                    children: [
                      Text("Publisher Info", style: TextStyle(fontSize: 22)),
                      Divider(),
                      ...widget.initData.publishers.asMap().entries.map((publisherEntry) {
                        IDEntity publisher = publisherEntry.value;
                        int index = publisherEntry.key;
                        return _NamedEntitySelect<IDEntity>(
                          paginationGetter: getPublishersPagination,
                          initNamedEntity: publisher,
                          onSelect: (IDEntity toChange) {
                            widget.initData.publishers[index] = toChange;
                          },
                          onDelete: (IDEntity toRemove) {
                            setState(() {
                              widget.initData.publishers.removeWhere((IDEntity pub) => pub.id == toRemove.id);
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
                                    content: PaginationWidget(
                                      futureGetter: getPublishersPagination,
                                      onSelect: (IDEntity newSelectedPublisher) {
                                        Navigator.of(context).pop(newSelectedPublisher);
                                      },
                                    ),
                                  );
                                });
                            if (futurePublisher != null) {
                              setState(() {
                                if (!widget.initData.publishers.contains(futurePublisher)) {
                                  widget.initData.publishers.add(futurePublisher);
                                }
                              });
                            }
                          }),
                      ListTile(
                        title: TextFormField(
                          initialValue: widget.initData.publishDate,
                          decoration: InputDecoration(labelText: "Publish Date"),
                        ),
                      ),
                    ],
                  )),
              // ),
              Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      Text("Author Info", style: TextStyle(fontSize: 22)),
                      Divider(),
                      ...widget.initData.authors.asMap().entries.map((authorEntry) {
                        Author author = authorEntry.value;
                        int index = authorEntry.key;
                        return _NamedEntitySelect<Author>(
                          paginationGetter: getAuthorsPagination,
                          initNamedEntity: author,
                          onSelect: (Author toChange) {
                            widget.initData.authors[index] = toChange;
                          },
                          onDelete: (Author toRemove) {
                            setState(() {
                              widget.initData.authors.removeWhere((Author pub) => pub.olID == toRemove.olID);
                            });
                          },
                        );
                      })
                    ],
                  ))
 */
