import 'package:flutter/material.dart';
import 'package:zigma2/src/RegisterPage.dart';
import 'package:zigma2/src/advert_creation.dart';
import 'package:zigma2/src/landing_page.dart';
import 'package:zigma2/src/login_page.dart';



class Routing{
  void routeLandingPage(context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => LandingPage()));
  }
  void routeRegisterPage(context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => RegisterPage()));
  }
  void routeLoginPage(context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => LoginPage()));
  }
  void routeCreationPage(context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => AdvertCreation()));
  }
}