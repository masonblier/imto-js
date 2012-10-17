imto-js
=======

A simple parser stack and api for interpreting imto. Works in the browser, command-line, and in node.js.

Getting Started
---------------

1. You must have node > 0.8 installed

2. Install dependencies

  ```
  npm install --dev
  ```

3. You can link it to use the imto command globally

  ```
  npm link
  imto
  ```

4. Usage:

  ```
  ./bin/imto-js -[LP] [filename]
  ````

  If no filename is given, interactive mode starts. L is lex only, P is lex and parse, default is eval.

5. Run tests:

  ```
  cake test
  ````

6. Build js files

  ```
  cake build
  ````

  If you are using imto from the command line, you must rebuild each time, or change the require in /bin/imto-js to /src rather than /lib.


License
-------

imto-js is released under the MIT license:

* http://www.opensource.org/licenses/MIT
