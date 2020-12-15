import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const String OPEN_LIB_API = "https://openlibrary.org";
const String COVER_OPEN_LIB_API = "https://covers.openlibrary.org";

class Book {
  int volume;
  String title;
  String imageURL;
  String edition;
  String publishDate;
  String format;
  String isbn;
  List<String> authors;
  List<String> publishers;

  Book.fromJson(Map<String, dynamic> json) {
    print(json);
    title = json["title"];
    authors = json["authors"];
    publishDate = json["publishDate"];
    publishers = List<String>.from(json["publishers"]);
    imageURL = json["imageURL"];
    format = json["physicalFormat"];
    isbn = json["isbn"];
  }
}

Future<List<Book>> getBooks() async {
  return null;
}

Future<bool> addBook() async {
  return null;
}

// dynamic OLNullParser(data, placeholder) {
//   if (data == null) {
//     return placeholder;
//   } else {
//     return data;
//   }
// }

Future<List<String>> parseAuthors(List<dynamic> potentialAuthors) async {
  /*
   * There's two cases for the author. Both are lists of dictionaries.
   * If the request is coming from the /api endpoint, there will be name/url
   * If the request is coming from the /isbn/.json endpoint, there will only
   * be key
   */

  if (potentialAuthors == null) {
    return ["Unknown"];
  }
  List<String> returnList = [];
  if (potentialAuthors.isNotEmpty) {
    for (dynamic authorDict in potentialAuthors) {
      String author = authorDict["name"];
      if (author == null) {
        String authorLink = authorDict["key"];
        if (authorLink == null) {
          authorLink = "${authorDict['url']}.json";
        } else {
          authorLink = "$OPEN_LIB_API/$authorLink.json";
        }

        http.Response authorRes =
        await http.get("$OPEN_LIB_API/$authorLink.json");

        if (authorRes.statusCode != 200) {
          // This is a very bad position to be in. We will have to define
          // the author as unknown.
          // TODO: Perhaps a little more can be done in this case
          returnList.add("Unknown");
        } else {
          Map<String, dynamic> authorJsonResponse = json.decode(authorRes.body);
          returnList.add(authorJsonResponse["name"]);
        }
      } else {
        returnList.add(author);
      }
    }
  } else {
    returnList.add("Unknown");
  }
  return returnList;
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
      Map<String, dynamic> jsonResponse = json.decode(isbnRes.body);
      List<String> authorsList;

      if (jsonResponse["author"] == null) {
        http.Response authorRes = await http.get(
            "$OPEN_LIB_API/api/books?bibkeys=ISBN:$ISBN&jscmd=data&format=json");
        if (authorRes.statusCode == 200) {
          List<dynamic> authorsDicts = json.decode(authorRes.body)["ISBN:$ISBN"]["authors"] as List<dynamic>;
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

      // If publishers are null this becomes an issue for a downstream task

      Map<String, dynamic> bookInfo = {
        "title": jsonResponse["title"],
        "authors": authorsList,
        "publishDate": jsonResponse["publish_date"],
        "publishers": jsonResponse["publishers"],
        "imageURL": "$COVER_OPEN_LIB_API/b/isbn/$ISBN.jpg",
        "physicalFormat": jsonResponse["physical_format"],
        "isbn": ISBN
      };
      return Book.fromJson(bookInfo);
    } else {
      return null;
    }
  }
}

Future<List<Book>> searchBooks(String term) {
  return null;
}
