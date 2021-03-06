import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import './app_bar.dart';

class CustomChildExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const ExampleAppBar(
            title: "Inline Examples",
            showGoBack: true,
          ),
          Expanded(
              child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20.0),
                child: const Text(
                  "Example of usage in a contained context",
                  style: const TextStyle(fontSize: 18.0),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
                height: 450.0,
                child: ClipRect(
                  child: Container(
                      decoration: const BoxDecoration(color: Colors.lightGreenAccent),
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: <Widget>[
                          const Text(
                            "Hello there, this is a text, and that is a svg",
                            style: const TextStyle(fontSize: 10.0),
                            textAlign: TextAlign.center,
                          ),
                          SvgPicture.asset(
                            "assets/firefox.svg",
                            height: 100.0,
                          )
                        ],
                      )),
                ),
              )
            ],
          ))
        ],
      ),
    );
  }
}
