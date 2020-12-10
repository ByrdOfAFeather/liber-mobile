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
  }
}

Future<List<Book>> getBooks() async {
  return null;
}

Future<bool> addBook() async {
  return null;
}

dynamic OLNullParser(data, placeholder) {
  if (data == null) {
    return placeholder;
  } else {
    return data;
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
      Map<String, dynamic> jsonResponse = json.decode(isbnRes.body);

      // Authors are returned in the form of a list of links to the author
      // pages. Thus, we have to loop and get each author.
      List<dynamic> authorsDicts = jsonResponse["authors"] as List<dynamic>;
      List<String> authorsList = [];

      print("THIS IS AUTHORS DICTS");
      print(authorsDicts);
      print("END =====");
      if (authorsDicts != null) {
        for (dynamic authorDict in authorsDicts) {
          String authorLink = authorDict["key"];
          http.Response authorRes =
          await http.get("$OPEN_LIB_API/$authorLink.json");
          if (authorRes.statusCode != 200) {
            // This is a very bad position to be in. We will have to define
            // the author as unknown.
            // TODO: Perhaps a little more can be done in this case
            authorsList.add("Failed to get author");
          }
          Map<String, dynamic> authorJsonResponse = json.decode(authorRes.body);
          authorsList.add(authorJsonResponse["name"]);
        }
      } else {
        authorsList.add("Unknown");
      }

      // If publishers are null this becomes an issue for a downstream task
      jsonResponse["publishers"] =
          OLNullParser(jsonResponse["publishers"], ["Unknown"]);
      jsonResponse["publish_date"] =
          OLNullParser(jsonResponse["publish_date"], "Unknown");

      Map<String, dynamic> bookInfo = {
        "title": jsonResponse["title"],
        "authors": authorsList,
        "publishDate": jsonResponse["publish_date"],
        "publishers": jsonResponse["publishers"],
        "imageURL": "$COVER_OPEN_LIB_API/b/isbn/$ISBN.jpg",
        "physicalFormat":
        OLNullParser(jsonResponse["physical_format"], "Unknown")
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
