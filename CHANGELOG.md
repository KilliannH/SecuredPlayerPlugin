## 1.1.2

This was originaly a fork from rxlabz's audioplayer,
but since the v1.1.0, it's also forked from the amazing team behind
luanpotter's audioplayer.

Again, all rewards go to luanpotter and rxlabz work for this plugin.
A huge thanks for them.


This release allows developers to query a remote url via HTTP with an Authorization Header.

--- changelog since 1.1.2
debug on player completion listener
--- changelog since 1.1.1
Added handlers for initialized & destroyed states
Updated Readme

--- changelog since 1.0.x
Seek functionality : Done
Secured player : Done
Destroy functionality : Done
Init functionality : Done

Low latency mode : TODO
Need a low latency mode as the Runnable for the Slider updates every 50 millis by default,
idk if it consumes a lot of resources or not atm.

Debug mode : TODO
Some callbacks from android part are made for debug purposes (read code comments), a debug flag should be implemented somewhere.

LockScreen player controls/notifications : TODO
It should be great to follow what luanpotter has made when the device is locked.

IOS Compatibility : TODO
Nothing tested atm for ios part.

Unit tests : TODO
Nothing done for this part yet.
-------

Again, all rewards to luanpotter and rxlabz for this plugin.