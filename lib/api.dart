import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const String OPEN_LIB_API = "https://openlibrary.org";
const String COVER_OPEN_LIB_API = "https://covers.openlibrary.org";
// const String LIBRARY_API = "https://liber-pl.herokuapp.com/api";
const String LIBRARY_API = "http://192.168.1.236:8000/api";

class NamedEntity {
  String name;
}

class Book implements NamedEntity {
  int volume;
  String name;
  String imageURL;
  String edition;
  String publishDate;
  String format;
  String isbn;
  String olID;
  List<Author> authors;
  List<IDEntity> publishers;

  Book.fromJson(Map<String, dynamic> json) {
    name = json["title"];
    authors = json["authors"];
    publishDate = json["publishDate"];
    publishers = List<IDEntity>.from((json["publishers"]));
    imageURL = json["imageURL"];
    format = json["physicalFormat"];
    isbn = json["isbn"];
    olID = json["olID"];
  }
}

enum IDEntityType { publisher, author }

class IDEntity implements NamedEntity {
  String name;
  String id;

  IDEntity.fromJson(Map<String, dynamic> json) {
    name = json["name"];
    id = json["id"].toString(); // TODO: This probably can be removed later if uuid is used
  }
}

class Author implements NamedEntity {
  String name;
  String olID;

  Author.fromJson(Map<String, dynamic> json) {
    name = json["name"];
    olID = json["olID"];
  }

  Author.unknown() {
    name = "Unknown";
    olID = "";
  }
}

class Work {
  String title;
  List<String> bookLinks;
  String initialPublishDate;
  List<String> authors;
  List<String> publishers;

  Work.fromJson(Map<String, dynamic> json) {
    title = json["title"];
    bookLinks = List<String>.from(json["bookLinks"]);
    initialPublishDate = json["initialPublishDate"]?.toString();
    authors = List<String>.from(json["authors"]);
    publishers = List<String>.from(json["publishers"]);
  }
}

Future<List<Book>> getBooks() async {
  return null;
}

Future<bool> addBook() async {
  return null;
}

Future<Map<String, dynamic>> getIDEntityPagination(int paginationIndex, IDEntityType paginationType) async {
  http.Response libRes = await http.get("$LIBRARY_API/$paginationType?pagination_index=$paginationIndex");
  if (libRes.statusCode == 200) {
    Map<String, dynamic> jsonRes = json.decode(libRes.body);
    List<IDEntity> entities;
    try {
      entities =
      List<IDEntity>.from(jsonRes["result"].map((publisherInfo) => IDEntity.fromJson(publisherInfo)).toList());
    } catch (e) {
      print(e);
    }
    return {"result": entities, "end_of_pagination": jsonRes["end_of_pagination"]};
  } else {
    return null;
  }
}

Future<Map<String, dynamic>> getPublishersPagination(int paginationIndex) async {
  return await getIDEntityPagination(paginationIndex, IDEntityType.publisher);
}

Future<Map<String, dynamic>> getAuthorsPagination(int paginationIndex) async {
  return await getIDEntityPagination(paginationIndex, IDEntityType.author);
}

Future<List<Author>> parseAuthors(List<dynamic> potentialAuthors) async {
  /*
   * There's two cases for the author. Both are lists of dictionaries.
   * If the request is coming from the /api endpoint, there will be name/url
   * If the request is coming from the /isbn/.json endpoint, there will only
   * be key
   */

  if (potentialAuthors == null) {
    return [Author.unknown()];
  }
  List<Author> returnList = [];
  if (potentialAuthors.isNotEmpty) {
    for (dynamic authorDict in potentialAuthors) {
      String author = authorDict["name"];
      if (author == null) {
        String authorLink = authorDict["key"];
        if (authorLink == null) {
          authorLink = "$OPEN_LIB_API/${authorDict['url']}.json";
        } else {
          authorLink = "$OPEN_LIB_API$authorLink.json";
        }

        http.Response authorRes = await http.get("$authorLink");

        if (authorRes.statusCode != 200) {
          // This is a very bad position to be in. We will have to define
          // the author as unknown.
          // TODO: Perhaps a little more can be done in this case
          // returnList.add(Author.fromJson(authorRes ));
          print("here");
        } else {
          Map<String, dynamic> authorJsonResponse = json.decode(authorRes.body);
          String name = authorJsonResponse["name"];
          RegExpMatch olIDMatch = RegExp("\/OL.*\\.").firstMatch(authorLink);
          String olID = authorLink.substring(olIDMatch.start + 1, olIDMatch.end - 1);
          Map<String, dynamic> authorInfo = {"name": name, "olID": olID};
          returnList.add(Author.fromJson(authorInfo));
        }
      } else {
        RegExpMatch regularExpression = RegExp("OL.*\/").firstMatch(authorDict["url"]);
        String olID = authorDict["url"].substring(regularExpression.start, regularExpression.end - 1);
        Map<String, dynamic> authorInfo = {"name": author, "olID": olID};
        returnList.add(Author.fromJson(authorInfo));
      }
    }
  } else {
    // returnList.add("Unknown");
  }
  return returnList;
}

Future<IDEntity> getOrCreateIDEntity(String entityName, IDEntityType entityType) async {
  String entitySafe = entityType.toString().replaceAll(RegExp("IDEntityType."), "");
  http.Response entityRes = await http.get("$LIBRARY_API/$entitySafe?name=$entityName");
  if (entityRes.statusCode == 200) {
    return IDEntity.fromJson(json.decode(entityRes.body));
  } else if (entityRes.statusCode == 404) {
    http.Response publisherCreateRes = await http.post("$LIBRARY_API/$entitySafe",
        body: json.encode(
          {"name": entityName},
        ),
        headers: {"content-type": "application/json"});
    if (publisherCreateRes.statusCode == 200) {
      return IDEntity.fromJson(json.decode(publisherCreateRes.body));
    } else {
      print("Hey I couldn't add $entityName");
      // publishers.add(null); // TODO: Handle this downstream
      return null;
    }
  } else {
    print("Hey I couldn't find or add $entityName");
    // publishers.add(null); // TODO: Again handle this downstream
    return null;
  }
}

Future<List<IDEntity>> getOrCreatePublishers(List<String> publisherNames) async {
  if (publisherNames == null) {
    return [];
  }
  List<IDEntity> publishers = [];
  for (String publisher in publisherNames) {
    IDEntity currentPub = await getOrCreateIDEntity(publisher, IDEntityType.publisher);
    if (currentPub != null) {
      publishers.add(currentPub);
    } else {
      // TODO: Here
    }
  }
  return publishers;
}

Future<List<IDEntity>> getOrCreateAuthors(List<String> authorNames) async {
  List<IDEntity> authors = [];
  if (authorNames == null) {
    return [];
  }
  for (String author in authorNames) {
    IDEntity currentAuthor = await getOrCreateIDEntity(author, IDEntityType.author);
    if (currentAuthor != null) {
      authors.add(currentAuthor);
    } else {
      // TODO: here
    }
  }
  return authors;
}

Future<Book> parseBook(http.Response res) async {
  Map<String, dynamic> jsonResponse = json.decode(res.body);
  List<Author> authorsList;
  String openLibID = (jsonResponse["key"] as String).replaceAll(RegExp("/books/"), "");
  if (jsonResponse["authors"] == null) {
    http.Response authorRes = await http.get("$OPEN_LIB_API/api/books?bibkeys=OLID:$openLibID&jscmd=data&format=json");
    if (authorRes.statusCode == 200) {
      List<dynamic> authorsDicts = json.decode(authorRes.body)["OLID:$openLibID"]["authors"] as List<dynamic>;
      authorsList = await parseAuthors(authorsDicts);
    } else {
      // TODO: This is the error case where there was not authors
      // in the book in the first place but then we had an error when
      // trying the alternate api
    }
  } else {
    // Authors are returned in the form of a list of links to the author
    // pages. Thus, we have to loop and get each author.
    List<dynamic> authorsDicts = jsonResponse["authors"] as List<dynamic>;
    authorsList = await parseAuthors(authorsDicts);
  }

  if (jsonResponse["publishers"] == null) {
    jsonResponse["publishers"] = [];
  } else {
    jsonResponse["publishers"] = await getOrCreatePublishers(List<String>.from(jsonResponse["publishers"]));
  }

  // Sets isbn_13 to isbn_10 if no isbn_13 is present
  // If isbn_10 isn't present we provide a placeholder list
  jsonResponse["isbn_13"] ??= jsonResponse["isbn_10"];
  jsonResponse["isbn_13"] ??= [""];

  String imageURL;
  if (jsonResponse["covers"] != null) {
    imageURL = "$COVER_OPEN_LIB_API/b/id/${jsonResponse["covers"][0]}.jpg";
  }

  print("VIEW ME FOR FORMAT");
  print(jsonResponse["physical_format"]);

  Map<String, dynamic> bookInfo = {
    "title": jsonResponse["title"],
    "authors": authorsList,
    "publishDate": jsonResponse["publish_date"],
    "publishers": jsonResponse["publishers"],
    "imageURL": imageURL,
    "physicalFormat": jsonResponse["physical_format"],
    "isbn": jsonResponse["isbn_13"][0],
    // TODO: It is strange that this is a list in the first place.....
    "olID": openLibID
  };
  return Book.fromJson(bookInfo);
}

Future<Book> searchOLByOLID(String olID) async {
  http.Response book = await http.get("$OPEN_LIB_API/books/$olID.json");
  if (book.statusCode == 200) {
    return await parseBook(book);
  } else {
    return null;
  }
}

Future<Book> searchOLByISBN(String ISBN) async {
  if (ISBN.length > 13 || ISBN.length < 9) {
    return null;
  } else {
    // This works for older books with only 9 characters for their ISBN number
    if (ISBN.length == 9) {
      ISBN = "0$ISBN";
    }

    // Initial query to get the book information
    http.Response isbnRes = await http.get("$OPEN_LIB_API/isbn/$ISBN.json");
    if (isbnRes.statusCode == 200) {
      Book book = await parseBook(isbnRes);
      return book;
    } else {
      return null;
    }
  }
}

Future<List<Work>> searchOLByName(String searchTerm, {String publisher}) async {
  String searchQuery = "title=$searchTerm";
  if (publisher != null) {
    searchQuery = "$searchQuery&publisher=$publisher";
  }
  http.Response searchResult = await http.get("$OPEN_LIB_API/search.json?$searchQuery");
  if (searchResult.statusCode == 200) {
    Map<String, dynamic> jsonResponse = json.decode(searchResult.body);
    List<Work> works = [];
    for (Map<String, dynamic> workRes in jsonResponse["docs"]) {
      // TODO: note that books with the same name (particularly obscure ones)
      // seem to confuse the system. There could be a way to work with this
      // but unclear as to how.
      Map<String, dynamic> parsedResponse = {};
      workRes["title"] ??= "";
      parsedResponse["title"] = workRes["title"];
      workRes["seed"] ??= [];
      parsedResponse["bookLinks"] = List<String>.from(workRes["seed"].where((dynamic link) {
        if ((link as String).startsWith("/books")) {
          return true;
        } else {
          return false;
        }
      }).toList());
      workRes["first_publish_year"] ??= "";
      parsedResponse["initialPublishDate"] = workRes["first_publish_year"];
      workRes["author_name"] ??= [];
      parsedResponse["authors"] = workRes["author_name"];
      workRes["publisher"] ??= [];
      parsedResponse["publishers"] = workRes["publisher"];
      works.add(Work.fromJson(parsedResponse));
    }
    return works;
  } else {
    return null;
  }
}

Future<List<Book>> getBooksFromWork(Work work) async {
  List<Book> books = [];
  for (String bookURL in work.bookLinks) {
    http.Response bookRes = await http.get("$OPEN_LIB_API$bookURL.json");
    if (bookRes.statusCode == 200) {
      Book curBook = await parseBook(bookRes);
      books.add(curBook);
    } else {
      // TODO: Not sure how to handle this particular error
    }
  }
  return books;
}

Future<List<Book>> searchBooks(String term) {
  return null;
}
