import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:zigma2/src/DataProvider.dart';
import 'package:zigma2/src/advert.dart';
import 'package:zigma2/src/components/carousel.dart';
import 'dart:async';

import 'package:zigma2/src/components/login_prompt.dart';
import 'package:zigma2/src/user.dart';
import 'package:zigma2/src/pages/profile_page.dart';

class AdvertPage extends StatefulWidget {
  final Advert data;

  AdvertPage({this.data});

  @override
  _AdvertPageState createState() => _AdvertPageState();
}

class _AdvertPageState extends State<AdvertPage> {
  //Build method
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'advert page',
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/advertPageBackground.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(30),
            child: AppBar(
              iconTheme: IconThemeData(color: Color(0xffECE9DF)),
              elevation: 0.0,
              backgroundColor: Colors.transparent,
            ),
          ),
          body: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(horizontal: 10),
            children: <Widget>[
              getAdvertTitle(),
              SizedBox(
                height: 25,
              ),
              getAdvertPictures(),
              SizedBox(
                height: 30,
              ),
              getText("Författare: ", widget.data.authors),
              getText("Upplaga: ", widget.data.edition),
              getText("Skick: ", widget.data.condition),
              getText("ISBN: ", widget.data.isbn),
              getAdvertPrice(),
              getOwnerName(),
              Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                  ),
                  getOwnerImage(),
                  getOwnerInformation(),
                ],
              ),
              getMessageButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget getAdvertTitle() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 25),
      alignment: Alignment(0, 0),
      height: 50,
      child: Text(
        widget.data.bookTitle,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          color: Color(0xFFECE9DF),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget getAdvertPictures() {
    return widget.data.images.length == 0
        ? Container(
            height: 300,
            child: Image.asset('images/placeholder_book.png'),
          )
        : Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.lightBlueAccent, width: 5)),
            margin: EdgeInsets.symmetric(horizontal: 75),
            height: 300,
            child: GestureDetector(
              onTap: () {
                carouselDialog();
              },
              child: Carousel(images: widget.data.images),
            ),
          );
  }

  Widget getAdvertPrice() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        widget.data.price.toString() + ":-",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 40,
          color: Color(0xff96070a),
        ),
      ),
    );
  }

  Widget getOwnerName() {
    return Center(
      child: Container(
        padding: EdgeInsets.only(top: 8, left: 10),
        child: FutureBuilder(
          future: getUser("username"),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                "Denna bok säljs av " + snapshot.data.username + ".",
                style: TextStyle(fontSize: 16),
              );
            } else {
              return Text(
                "Denna bok säljs av " + "laddar...",
                style: TextStyle(fontSize: 16),
              );
            }
          },
        ),
      ),
    );
  }

  Widget getOwnerImage() {
    return FutureBuilder(
      future: getUser("img_link"),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data.image == null
              ? Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: GestureDetector(
                      onTap: () => getOwnerAdvertLists(),
                      child: Icon(
                        Icons.account_circle,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              : Expanded(
                  flex: 2,
                  child: Stack(
                    alignment: Alignment(0, 0),
                    children: <Widget>[
                      Center(child: CircularProgressIndicator()),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: GestureDetector(
                          onTap: () => getOwnerAdvertLists(),
                          child: Container(
                            width: 50,
                            height: 50,
                            child: FadeInImage.memoryNetwork(
                              fit: BoxFit.fitWidth,
                              placeholder: kTransparentImage,
                              image: snapshot.data.image,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
        } else {
          return Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.none,
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  Widget getOwnerInformation() {
    return Expanded(
      flex: 8,
      child: FutureBuilder(
        future: getUser("username,sold_books,bought_books"),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(
              snapshot.data.username +
                  " har sålt " +
                  snapshot.data.soldBooks.toString() +
                  " böcker och köpt " +
                  snapshot.data.boughtBooks.toString() +
                  " böcker.",
              textAlign: TextAlign.center,
            );
          } else {
            return Text("Laddar... har sålt ... böcker och köpt ... böcker.");
          }
        },
      ),
    );
  }

  List<int> stringIdListToInt(List ids) {
    final List<int> intIds = [];
    for (var id in ids) {
      assert(id is int);
      intIds.add(id);
    }
    return intIds;
  }

  Future<List> getOwnerAdvertLists() async {
    final List<Advert> buyingAdvertList = [];
    final List<Advert> sellingAdvertList = [];
    User tempUser = await getUser("adverts");
    List<Advert> ownerAdvertList = await DataProvider.of(context)
        .advertList
        .getAdvertsFromIds(stringIdListToInt(tempUser.adverts));
    for (Advert ad in ownerAdvertList) {
      if (ad.transaction_type=="B") {
        buyingAdvertList.add(ad);
      }
      else {
        sellingAdvertList.add(ad);
      }
    }
    return ownerAdvertList;
  }
  Future<Widget> _profilePictureStyled()  async {
    String userPictureURI = await getUser("image");
    return Hero(
      tag: 'advertProfile',
      child: GestureDetector(
        onTap: () {
          profilePicDialog();
        },
        child: Center(
          child: Container(
            child: CircleAvatar(
              backgroundColor: Color(0xFF95453),
              radius: 75,
              backgroundImage: NetworkImage(userPictureURI),
            ),
          ),
        ),
      ),
    );
  }
  Widget _profileRatingStyled() {
    return Center(
      child: RichText(
        text: TextSpan(
          // set the default style for the children TextSpans
            style: Theme.of(context).textTheme.body1.copyWith(fontSize: 20),
            children: [
              TextSpan(
                text: DataProvider.of(context).user.user.soldBooks > 5
                    ? "Mellanliggande Bokförsäljare"
                    : "Novis Bokförsäljare",
                // Email tills vidare
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ]),
      ),
    );
  }


  void profilePicDialog() {
    print("Im in show alertDialog");
    Dialog dialog = Dialog(
      insetAnimationCurve: Curves.decelerate,
      insetAnimationDuration: Duration(milliseconds: 500),
      backgroundColor: Color(0xFFECE9DF),
      child: Container(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Image.network(DataProvider.of(context).user.user.image),
        ),
      ),
    );
    showDialog(context: context, builder: (BuildContext context) => dialog);
  }


  void getOwnerProfile() async {
    final List<Advert> buyingAdvertList = [];
    final List<Advert> sellingAdvertList = [];
    final List<Advert> userAdverts = await getOwnerAdvertLists();
    for (Advert ad in userAdverts) {
      if (ad.transaction_type=="B") {
        buyingAdvertList.add(ad);
      }
      else {
        sellingAdvertList.add(ad);
      }
    }

    userAdverts.clear;
    int initialPage = 0;
    List<dynamic> returnList;
    int stateButtonIndex = initialPage;
    final controller = PageController(
      initialPage: initialPage,
    );
    Dialog dialog = Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: ListView(children: <Widget>[])),
    );
    showDialog(context: context, builder: (context) => dialog);
  }

  Widget getMessageButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Container(),
        ),
        Expanded(
          flex: 6,
          child: RaisedButton(
            color: Colors.blueGrey,
            onPressed: () {
              developerDialog();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Icon(
                    Icons.chat_bubble,
                    size: 30,
                    color: Color(0xff96070a),
                  ),
                  flex: 2,
                ),
                Expanded(
                  child: FutureBuilder(
                    future: getUser("username"),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          "Skicka ett meddelande till " +
                              snapshot.data.username,
                          textAlign: TextAlign.center,
                        );
                      } else {
                        return Text(
                          "Skicka ett meddelande till " + "laddar...",
                          textAlign: TextAlign.center,
                        );
                      }
                    },
                  ),
                  flex: 8,
                )
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(),
        ),
      ],
    );
  }

  Future<dynamic> getUser(String fields) async {
    var userData = await DataProvider.of(context)
        .user
        .getUserById(widget.data.owner, fields);
    return userData;
  }

  void developerDialog() {
    Dialog dialog = Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height / 3,
        child: Center(
          child: DataProvider.of(context).user.user == null
              ? LoginPrompt()
              : Text(
                  "Denna knapp är ej implementerad :(",
                  style: TextStyle(fontSize: 45),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
    showDialog(context: context, builder: (context) => dialog);
  }

  void carouselDialog() {
    Dialog dialog = Dialog(
      child: Container(
        height: MediaQuery.of(context).size.height / 2,
        child: Carousel(images: widget.data.images),
      ),
    );
    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  Widget getText(leading, content) {
    if (content == "") {
      return SizedBox(
        height: 0,
        width: 0,
      );
    } else {
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: leading,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xff96070a),
          ),
          children: [
            TextSpan(
              text: content,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }
  }
}
