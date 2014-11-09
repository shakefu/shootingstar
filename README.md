# Shooting Star

This is a node.js event-based chat server. It allows multiple users to connect,
create rooms, and chat with one another.

The server does not persist any channels or user connections through a reboot.
It also does not persist any chat messages.

This server does not also truly implement the telnet protocol. It's pretty dumb
that way. So, it might get stuck on control characters, or have odd behavior if
you're using a telnet client that wants to send WILL/WONT/DO/DONT, etc. It may
work if you inline ANSI control/color codes while chatting, but I haven't
tested it.

There is a demo server running at `jake-alheid.me 9399`.

## Installation for development

```bash
$ git clone git@github.com:shakefu/shootingstar.git
$ cd shootingstar
$ npm install
```

If this was a more serious project, it would be properly built and available on
npm or a privately hosted npm for regular installation. But since I don't want
to pollute npm, it isn't.

## Running the server for development

This repository includes a grunt file which will run the server, as well as
recompile coffeescript, restart the server, and run tests on file changes.

If you don't have it, you need `grunt-cli`, otherwise you can skip that step.

```bash
$ npm install -g grunt-cli
$ grunt
```

By default, the server will run on port 9399.

## Running the server for fun

The only thing that needs to be done to run the server outside development is
compile the coffeescript to JS. This can be done with grunt or the `coffee`
command.

Grunt is perferable since it's already configured, but requires the `grunt-cli`
package be installed.

Settings like the IP to bind to, and port number to run on can be overridden on
the command line. Check out `src/config.coffee` for a full listing.

```bash
$ grunt coffee
$ HOST=0.0.0.0 PORT=1234 node lib/server.js
```

## Running tests

If you're running the server in development mode, grunt will automatically run
tests for you on file changes. If you'd like to run a one-off of the tests, use
`grunt test`.

# Bonus

This repository also includes a UI based chat server that's very similar to the
telnet server. It was an experiment to see if it was possible to build a
realtime chat server using the MeteorJS framework, done purely for my own
entertainment and curiousity, so it's lacking tests and documentation.

There's a copy of this server running at http://jakechat.meteor.com that
you're welcome to try out.

## Running the meteor chat server

Just move into the meteor project directory and type `meteor` to run the server
in development mode.

```bash
$ cd shootingstar/meteor/shootingstar
$ meteor
```

Connect to `http://localhost:3000` to use it.

