# securedplayerflutterplugin

This was originaly a fork from rxlabz's audioplayer, but since the v1.1.0, it's also forked from the amazing team behind luanpotter's audioplayer.

Again, all rewards go to luanpotter and rxlabz work for this plugin. A huge thanks for them.

This release allows developers to query a remote url via HTTP with an Authorization Header.

--- changelog since 1.0.x Seek functionality : Done Secured player : Done Destroy functionality : Done Init functionality : Done

Low latency mode : TODO Need a low latency mode as the Runnable for the Slider updates every 50 millis by default, idk if it consumes a lot of resources or not atm.

Debug mode : TODO Some callbacks from android part are made for debug purposes (read code comments), a debug flag should be implemented somewhere.

LockScreen player controls/notifications : TODO It should be great to follow what luanpotter has made when the device is locked.

IOS Compatibility : TODO Nothing tested atm for ios part.

It has no test coverage (yet).

/ ! \ don't forget to use a protocol for your remote url (http, https.. etc),
otherwise android will think you try to play a localfile.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.
