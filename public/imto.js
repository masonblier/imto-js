(function(){var require = function (file, cwd) {
    var resolved = require.resolve(file, cwd || '/');
    var mod = require.modules[resolved];
    if (!mod) throw new Error(
        'Failed to resolve module ' + file + ', tried ' + resolved
    );
    var cached = require.cache[resolved];
    var res = cached? cached.exports : mod();
    return res;
};

require.paths = [];
require.modules = {};
require.cache = {};
require.extensions = [".js",".coffee",".json"];

require._core = {
    'assert': true,
    'events': true,
    'fs': true,
    'path': true,
    'vm': true
};

require.resolve = (function () {
    return function (x, cwd) {
        if (!cwd) cwd = '/';
        
        if (require._core[x]) return x;
        var path = require.modules.path();
        cwd = path.resolve('/', cwd);
        var y = cwd || '/';
        
        if (x.match(/^(?:\.\.?\/|\/)/)) {
            var m = loadAsFileSync(path.resolve(y, x))
                || loadAsDirectorySync(path.resolve(y, x));
            if (m) return m;
        }
        
        var n = loadNodeModulesSync(x, y);
        if (n) return n;
        
        throw new Error("Cannot find module '" + x + "'");
        
        function loadAsFileSync (x) {
            x = path.normalize(x);
            if (require.modules[x]) {
                return x;
            }
            
            for (var i = 0; i < require.extensions.length; i++) {
                var ext = require.extensions[i];
                if (require.modules[x + ext]) return x + ext;
            }
        }
        
        function loadAsDirectorySync (x) {
            x = x.replace(/\/+$/, '');
            var pkgfile = path.normalize(x + '/package.json');
            if (require.modules[pkgfile]) {
                var pkg = require.modules[pkgfile]();
                var b = pkg.browserify;
                if (typeof b === 'object' && b.main) {
                    var m = loadAsFileSync(path.resolve(x, b.main));
                    if (m) return m;
                }
                else if (typeof b === 'string') {
                    var m = loadAsFileSync(path.resolve(x, b));
                    if (m) return m;
                }
                else if (pkg.main) {
                    var m = loadAsFileSync(path.resolve(x, pkg.main));
                    if (m) return m;
                }
            }
            
            return loadAsFileSync(x + '/index');
        }
        
        function loadNodeModulesSync (x, start) {
            var dirs = nodeModulesPathsSync(start);
            for (var i = 0; i < dirs.length; i++) {
                var dir = dirs[i];
                var m = loadAsFileSync(dir + '/' + x);
                if (m) return m;
                var n = loadAsDirectorySync(dir + '/' + x);
                if (n) return n;
            }
            
            var m = loadAsFileSync(x);
            if (m) return m;
        }
        
        function nodeModulesPathsSync (start) {
            var parts;
            if (start === '/') parts = [ '' ];
            else parts = path.normalize(start).split('/');
            
            var dirs = [];
            for (var i = parts.length - 1; i >= 0; i--) {
                if (parts[i] === 'node_modules') continue;
                var dir = parts.slice(0, i + 1).join('/') + '/node_modules';
                dirs.push(dir);
            }
            
            return dirs;
        }
    };
})();

require.alias = function (from, to) {
    var path = require.modules.path();
    var res = null;
    try {
        res = require.resolve(from + '/package.json', '/');
    }
    catch (err) {
        res = require.resolve(from, '/');
    }
    var basedir = path.dirname(res);
    
    var keys = (Object.keys || function (obj) {
        var res = [];
        for (var key in obj) res.push(key);
        return res;
    })(require.modules);
    
    for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        if (key.slice(0, basedir.length + 1) === basedir + '/') {
            var f = key.slice(basedir.length);
            require.modules[to + f] = require.modules[basedir + f];
        }
        else if (key === basedir) {
            require.modules[to] = require.modules[basedir];
        }
    }
};

(function () {
    var process = {};
    var global = typeof window !== 'undefined' ? window : {};
    var definedProcess = false;
    
    require.define = function (filename, fn) {
        if (!definedProcess && require.modules.__browserify_process) {
            process = require.modules.__browserify_process();
            definedProcess = true;
        }
        
        var dirname = require._core[filename]
            ? ''
            : require.modules.path().dirname(filename)
        ;
        
        var require_ = function (file) {
            var requiredModule = require(file, dirname);
            var cached = require.cache[require.resolve(file, dirname)];

            if (cached && cached.parent === null) {
                cached.parent = module_;
            }

            return requiredModule;
        };
        require_.resolve = function (name) {
            return require.resolve(name, dirname);
        };
        require_.modules = require.modules;
        require_.define = require.define;
        require_.cache = require.cache;
        var module_ = {
            id : filename,
            filename: filename,
            exports : {},
            loaded : false,
            parent: null
        };
        
        require.modules[filename] = function () {
            require.cache[filename] = module_;
            fn.call(
                module_.exports,
                require_,
                module_,
                module_.exports,
                dirname,
                filename,
                process,
                global
            );
            module_.loaded = true;
            return module_.exports;
        };
    };
})();


require.define("path",function(require,module,exports,__dirname,__filename,process,global){function filter (xs, fn) {
    var res = [];
    for (var i = 0; i < xs.length; i++) {
        if (fn(xs[i], i, xs)) res.push(xs[i]);
    }
    return res;
}

// resolves . and .. elements in a path array with directory names there
// must be no slashes, empty elements, or device names (c:\) in the array
// (so also no leading and trailing slashes - it does not distinguish
// relative and absolute paths)
function normalizeArray(parts, allowAboveRoot) {
  // if the path tries to go above the root, `up` ends up > 0
  var up = 0;
  for (var i = parts.length; i >= 0; i--) {
    var last = parts[i];
    if (last == '.') {
      parts.splice(i, 1);
    } else if (last === '..') {
      parts.splice(i, 1);
      up++;
    } else if (up) {
      parts.splice(i, 1);
      up--;
    }
  }

  // if the path is allowed to go above the root, restore leading ..s
  if (allowAboveRoot) {
    for (; up--; up) {
      parts.unshift('..');
    }
  }

  return parts;
}

// Regex to split a filename into [*, dir, basename, ext]
// posix version
var splitPathRe = /^(.+\/(?!$)|\/)?((?:.+?)?(\.[^.]*)?)$/;

// path.resolve([from ...], to)
// posix version
exports.resolve = function() {
var resolvedPath = '',
    resolvedAbsolute = false;

for (var i = arguments.length; i >= -1 && !resolvedAbsolute; i--) {
  var path = (i >= 0)
      ? arguments[i]
      : process.cwd();

  // Skip empty and invalid entries
  if (typeof path !== 'string' || !path) {
    continue;
  }

  resolvedPath = path + '/' + resolvedPath;
  resolvedAbsolute = path.charAt(0) === '/';
}

// At this point the path should be resolved to a full absolute path, but
// handle relative paths to be safe (might happen when process.cwd() fails)

// Normalize the path
resolvedPath = normalizeArray(filter(resolvedPath.split('/'), function(p) {
    return !!p;
  }), !resolvedAbsolute).join('/');

  return ((resolvedAbsolute ? '/' : '') + resolvedPath) || '.';
};

// path.normalize(path)
// posix version
exports.normalize = function(path) {
var isAbsolute = path.charAt(0) === '/',
    trailingSlash = path.slice(-1) === '/';

// Normalize the path
path = normalizeArray(filter(path.split('/'), function(p) {
    return !!p;
  }), !isAbsolute).join('/');

  if (!path && !isAbsolute) {
    path = '.';
  }
  if (path && trailingSlash) {
    path += '/';
  }
  
  return (isAbsolute ? '/' : '') + path;
};


// posix version
exports.join = function() {
  var paths = Array.prototype.slice.call(arguments, 0);
  return exports.normalize(filter(paths, function(p, index) {
    return p && typeof p === 'string';
  }).join('/'));
};


exports.dirname = function(path) {
  var dir = splitPathRe.exec(path)[1] || '';
  var isWindows = false;
  if (!dir) {
    // No dirname
    return '.';
  } else if (dir.length === 1 ||
      (isWindows && dir.length <= 3 && dir.charAt(1) === ':')) {
    // It is just a slash or a drive letter with a slash
    return dir;
  } else {
    // It is a full dirname, strip trailing slash
    return dir.substring(0, dir.length - 1);
  }
};


exports.basename = function(path, ext) {
  var f = splitPathRe.exec(path)[2] || '';
  // TODO: make this comparison case-insensitive on windows?
  if (ext && f.substr(-1 * ext.length) === ext) {
    f = f.substr(0, f.length - ext.length);
  }
  return f;
};


exports.extname = function(path) {
  return splitPathRe.exec(path)[3] || '';
};

});

require.define("__browserify_process",function(require,module,exports,__dirname,__filename,process,global){var process = module.exports = {};

process.nextTick = (function () {
    var canSetImmediate = typeof window !== 'undefined'
        && window.setImmediate;
    var canPost = typeof window !== 'undefined'
        && window.postMessage && window.addEventListener
    ;

    if (canSetImmediate) {
        return window.setImmediate;
    }

    if (canPost) {
        var queue = [];
        window.addEventListener('message', function (ev) {
            if (ev.source === window && ev.data === 'browserify-tick') {
                ev.stopPropagation();
                if (queue.length > 0) {
                    var fn = queue.shift();
                    fn();
                }
            }
        }, true);

        return function nextTick(fn) {
            queue.push(fn);
            window.postMessage('browserify-tick', '*');
        };
    }

    return function nextTick(fn) {
        setTimeout(fn, 0);
    };
})();

process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];

process.binding = function (name) {
    if (name === 'evals') return (require)('vm')
    else throw new Error('No such module. (Possibly not yet loaded)')
};

(function () {
    var cwd = '/';
    var path;
    process.cwd = function () { return cwd };
    process.chdir = function (dir) {
        if (!path) path = require('path');
        cwd = path.resolve(dir, cwd);
    };
})();

});

require.define("/interpreter.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.3.3
(function() {
  var Context, Interpreter, Lexer, Parser, clc;

  clc = {
    green: function(a) {
      return a;
    },
    blue: function(a) {
      return a;
    },
    red: function(a) {
      return a;
    }
  };

  Context = require('./context');

  Lexer = require('./lexer');

  Parser = require('./parser');

  Interpreter = (function() {

    function Interpreter() {
      this.context = new Context();
    }

    Interpreter.prototype.lex = function(code) {
      return new Lexer(code);
    };

    Interpreter.prototype.parse = function(code) {
      return new Parser(new Lexer(code));
    };

    Interpreter.prototype["eval"] = function(code) {
      return this.context.myvar = "1";
    };

    Interpreter.prototype.print = function(list, indent) {
      var head, node;
      if (indent == null) {
        indent = "";
      }
      if ((list != null ? list.all : void 0) != null) {
        list = list.all();
      }
      return console.log(list ? ((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = list.length; _i < _len; _i++) {
          node = list[_i];
          head = "" + indent + "(" + (clc.green(node.type));
          if (node.type === "function") {
            _results.push("" + head + "\n" + (this.print([node.body], indent + "  ")) + "\n" + indent + ")");
          } else if (node.type === "assignment" || node.type === "property_assignment") {
            _results.push("" + head + " " + (clc.blue("" + node.symbol)) + "\n" + (this.print([node.value], indent + "  ")) + "\n" + indent + ")");
          } else if (node.type === "literal") {
            _results.push("" + head + " " + (clc.red(node.token)) + ")");
          } else {
            _results.push("" + head + " '" + node.token + "')");
          }
        }
        return _results;
      }).call(this)).join("\n") : list);
    };

    return Interpreter;

  })();

  module.exports = Interpreter;

}).call(this);

});

require.define("/context.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.3.3
(function() {
  var Context;

  Context = (function() {

    function Context() {}

    return Context;

  })();

  module.exports = Context;

}).call(this);

});

require.define("/lexer.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.3.3
(function() {
  var CharCursor, Cursor, Lexer, OPERATORS, SyntaxError, WHITESPACE,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Cursor = require("./cursor");

  WHITESPACE = [' ', '\t'];

  OPERATORS = ['=', '+', '-', '*', '/', '<', '>', '%', '&', '(', ')', '[', ']', '^', ':', '?', '.'];

  SyntaxError = (function(_super) {

    __extends(SyntaxError, _super);

    function SyntaxError() {
      return SyntaxError.__super__.constructor.apply(this, arguments);
    }

    return SyntaxError;

  })(Error);

  CharCursor = (function(_super) {

    __extends(CharCursor, _super);

    function CharCursor(input) {
      var acc, line, _i, _len, _ref;
      this.input = input;
      this.indent = __bind(this.indent, this);

      this.at = __bind(this.at, this);

      CharCursor.__super__.constructor.call(this);
      this.input = this.input.replace("\r", "");
      this.length = this.input.length;
      this.lines = this.input.split("\n");
      this.line_ends = [];
      this.indents = [];
      acc = 0;
      _ref = this.lines;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        acc += line.length;
        this.line_ends.push(acc);
        if (acc < this.input.length) {
          acc += 1;
        }
      }
      if (acc !== this.input.length) {
        throw new Error("Tracking went wrong " + acc + ", " + this.input.length);
      }
    }

    CharCursor.prototype.at = function(index) {
      var line;
      if (index < 0 || index >= this.input.length) {
        return void 0;
      }
      line = 0;
      while (index > this.line_ends[line]) {
        line++;
      }
      return {
        line: line,
        column: index - (line > 0 ? this.line_ends[line - 1] + 1 : 0),
        char: this.input[index]
      };
    };

    CharCursor.prototype.indent = function(index) {
      var indent, line, _ref;
      line = 0;
      while (line < this.line_ends.length && index > this.line_ends[line]) {
        line++;
      }
      indent = this.indents[line] != null ? this.indents[line] : 0;
      if (indent === 0) {
        while (_ref = this.lines[line][indent], __indexOf.call(WHITESPACE, _ref) >= 0) {
          indent++;
        }
      }
      return indent;
    };

    return CharCursor;

  })(Cursor);

  module.exports = Lexer = (function(_super) {

    __extends(Lexer, _super);

    Lexer.CharCursor = CharCursor;

    function Lexer(input) {
      this.next_token = __bind(this.next_token, this);

      this.at = __bind(this.at, this);
      Lexer.__super__.constructor.call(this);
      this.memo_index = -1;
      this.memos = [];
      this.linestart = true;
      this.indent = 0;
      this.char_cursor = new CharCursor(input);
      while (this.char_cursor.peek().char === "\n") {
        this.char_cursor.next();
      }
    }

    Lexer.prototype.at = function(req_index) {
      while (this.memo_index < req_index) {
        if (!this.memos[this.memo_index += 1]) {
          this.memos[this.memo_index] = this.next_token();
        }
      }
      return this.memos[req_index];
    };

    Lexer.prototype.next_token = function() {
      var boundary, buffer, cc, i, indent, line, lookahead, source, stack, tracking_start, type, ws, _ref, _ref1, _ref10, _ref11, _ref12, _ref13, _ref14, _ref15, _ref16, _ref17, _ref18, _ref19, _ref2, _ref20, _ref21, _ref22, _ref23, _ref24, _ref25, _ref26, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
      buffer = '';
      cc = this.char_cursor;
      ws = 1;
      while (_ref = (_ref1 = cc.peek(ws)) != null ? _ref1.char : void 0, __indexOf.call(WHITESPACE, _ref) >= 0) {
        ws += 1;
      }
      if (ws > 1 && ((_ref2 = cc.peek(ws)) != null ? _ref2.char : void 0) === "\n") {
        cc.next(ws);
      }
      while (((_ref3 = cc.peek()) != null ? _ref3.char : void 0) === "\n" && ((_ref4 = cc.peek(2)) != null ? _ref4.char : void 0) === "\n") {
        cc.next();
      }
      while (((_ref5 = cc.peek()) != null ? _ref5.char : void 0) === "\n" && cc.indent(cc.index + 1) > this.indent) {
        cc.next();
      }
      tracking_start = cc.peek();
      if (cc.indent(cc.index) > this.indent && ((_ref6 = cc.peek()) != null ? _ref6.char : void 0) !== "\n") {
        indent = cc.indent(cc.index);
        while (cc.index < cc.length && (cc.indent(cc.index) > this.indent)) {
          buffer += cc.next().char;
        }
        if (((_ref7 = cc.prev(0)) != null ? _ref7.char : void 0) === "\n") {
          cc.back();
          buffer = buffer.substr(0, buffer.length - 1);
        }
        source = ((function() {
          var _i, _len, _ref8, _results;
          _ref8 = buffer.split("\n");
          _results = [];
          for (_i = 0, _len = _ref8.length; _i < _len; _i++) {
            line = _ref8[_i];
            _results.push(line.substr(indent));
          }
          return _results;
        })()).join("\n");
        return {
          type: 'block',
          token: buffer,
          source: source,
          tracking: {
            start: tracking_start,
            end: cc.peek(0)
          }
        };
      }
      while (_ref8 = (_ref9 = cc.peek()) != null ? _ref9.char : void 0, __indexOf.call(WHITESPACE, _ref8) >= 0) {
        cc.next();
      }
      if (!(cc.index < cc.length)) {
        return null;
      }
      tracking_start = cc.peek();
      if ((_ref10 = cc.peek().char) === "{" || _ref10 === "[" || _ref10 === "(") {
        stack = 1;
        buffer = cc.next().char;
        type = 'block';
        while (stack > 0 && cc.index < cc.length) {
          if ((_ref11 = cc.peek().char) === "}" || _ref11 === "]" || _ref11 === ")") {
            stack -= 1;
          }
          if ((_ref12 = cc.peek().char) === "{" || _ref12 === "[" || _ref12 === "(") {
            stack += 1;
          }
          buffer += cc.next().char;
        }
        if (stack > 0) {
          throw new SyntaxError("Unbalanced Parenthesis");
        }
        source = buffer.substring(1, buffer.length - 1);
        lookahead = 1;
        while (_ref13 = (_ref14 = cc.peek(lookahead)) != null ? _ref14.char : void 0, __indexOf.call(WHITESPACE, _ref13) >= 0) {
          lookahead += 1;
        }
        if (((_ref15 = cc.peek(lookahead)) != null ? _ref15.char : void 0) === "-" && ((_ref16 = cc.peek(lookahead + 1)) != null ? _ref16.char : void 0) === ">") {
          buffer += ((function() {
            var _i, _ref17, _results;
            _results = [];
            for (i = _i = 0, _ref17 = lookahead + 1; 0 <= _ref17 ? _i <= _ref17 : _i >= _ref17; i = 0 <= _ref17 ? ++_i : --_i) {
              _results.push(cc.peek(i).char);
            }
            return _results;
          })()).join("");
          cc.index = cc.index + lookahead + 1;
          type = 'function';
        }
        ws = 0;
        while (_ref17 = source[ws], __indexOf.call(WHITESPACE, _ref17) >= 0) {
          ws += 1;
        }
        source = source.substring(ws);
        if (source[0] === "\n") {
          source = source.substring(1);
          indent = 0;
          while (_ref18 = source[indent], __indexOf.call(WHITESPACE, _ref18) >= 0) {
            indent += 1;
          }
          source = ((function() {
            var _i, _len, _ref19, _results;
            _ref19 = source.split("\n");
            _results = [];
            for (_i = 0, _len = _ref19.length; _i < _len; _i++) {
              line = _ref19[_i];
              _results.push(line.substr(indent));
            }
            return _results;
          })()).join("\n");
        }
        return {
          type: type,
          token: buffer,
          source: source,
          tracking: {
            start: tracking_start,
            end: cc.peek(0)
          }
        };
      }
      if (_ref19 = cc.peek().char, __indexOf.call(OPERATORS, _ref19) >= 0) {
        while (_ref20 = (_ref21 = cc.peek()) != null ? _ref21.char : void 0, __indexOf.call(OPERATORS, _ref20) >= 0) {
          buffer += cc.next().char;
        }
        return {
          type: "operator",
          token: buffer,
          tracking: {
            start: tracking_start,
            end: cc.peek(0)
          }
        };
      }
      if (/([a-zA-Z_@])/.test(cc.peek().char)) {
        buffer = cc.next().char;
        while ((cc.peek() != null) && /([a-zA-Z0-9_])/.test(cc.peek().char)) {
          buffer += cc.next().char;
        }
        return {
          type: "symbol",
          token: buffer,
          tracking: {
            start: tracking_start,
            end: cc.peek(0)
          }
        };
      }
      if (/([0-9])/.test(cc.peek().char)) {
        while ((cc.peek() != null) && /([0-9]|\.|\,)/.test(cc.peek().char)) {
          buffer += cc.next().char;
        }
        if (((_ref22 = cc.prev(0)) != null ? _ref22.char : void 0) === ',') {
          buffer = buffer.substr(0, buffer.length - 1);
        }
        return {
          type: "number",
          token: buffer,
          value: parseFloat(buffer.replace(",", "")),
          tracking: {
            start: tracking_start,
            end: cc.peek(0)
          }
        };
      }
      if ((_ref23 = cc.peek().char) === "'" || _ref23 === '"') {
        boundary = cc.next().char;
        while ((cc.peek() != null) && ((_ref25 = cc.peek()) != null ? _ref25.char : void 0) !== boundary) {
          buffer += cc.next().char;
          if (((_ref24 = cc.peek()) != null ? _ref24.char : void 0) === "\\") {
            buffer += cc.next().char;
            buffer += cc.next().char;
          }
        }
        if (((_ref26 = cc.next()) != null ? _ref26.char : void 0) === boundary) {
          return {
            type: "string",
            token: "" + boundary + buffer + boundary,
            value: buffer,
            tracking: {
              start: tracking_start,
              end: cc.peek(0)
            }
          };
        } else {
          throw new SyntaxError("Unterminated String");
        }
      }
      if (cc.peek().char === "\n") {
        cc.next();
        return {
          type: 'linefeed',
          token: "\n",
          tracking: {
            start: tracking_start,
            end: cc.peek(0)
          }
        };
      }
      throw new SyntaxError("Unknown token: " + (cc.peek()));
    };

    return Lexer;

  })(Cursor);

}).call(this);

});

require.define("/cursor.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.3.3
(function() {
  var Cursor,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Cursor = (function() {

    function Cursor() {
      this.prev = __bind(this.prev, this);

      this.peek = __bind(this.peek, this);

      this.back = __bind(this.back, this);

      this.next = __bind(this.next, this);

      this.all = __bind(this.all, this);
      this.index = 0;
    }

    Cursor.prototype.all = function() {
      var t, _results;
      _results = [];
      while (t = this.next()) {
        _results.push(t);
      }
      return _results;
    };

    Cursor.prototype.next = function(i) {
      if (i == null) {
        i = 1;
      }
      return this.at((this.index += i) - 1);
    };

    Cursor.prototype.back = function(i) {
      if (i == null) {
        i = 1;
      }
      return this.at((this.index -= i) - 1);
    };

    Cursor.prototype.peek = function(i) {
      if (i == null) {
        i = 1;
      }
      return this.at((this.index + i) - 1);
    };

    Cursor.prototype.prev = function(i) {
      if (i == null) {
        i = 1;
      }
      return this.at((this.index - i) - 1);
    };

    return Cursor;

  })();

  module.exports = Cursor;

}).call(this);

});

require.define("/parser.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.3.3
(function() {
  var Cursor, Lexer, Parser,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Lexer = require('./lexer');

  Cursor = require('./Cursor');

  module.exports = Parser = (function(_super) {

    __extends(Parser, _super);

    function Parser(lexer) {
      this.lexer = lexer;
      this.local_assignment = __bind(this.local_assignment, this);

      this.property_assignment = __bind(this.property_assignment, this);

      this.assignment = __bind(this.assignment, this);

      this["function"] = __bind(this["function"], this);

      this.block = __bind(this.block, this);

      this.expr = __bind(this.expr, this);

      this.statement = __bind(this.statement, this);

      this.at = __bind(this.at, this);

      Parser.__super__.constructor.call(this);
      this.memo_index = -1;
      this.memos = [];
    }

    Parser.prototype.at = function(req_index) {
      while (this.memo_index < req_index) {
        if (!this.memos[this.memo_index += 1]) {
          this.memos[this.memo_index] = this.statement();
        }
      }
      return this.memos[req_index];
    };

    Parser.prototype.statement = function() {
      var subject;
      subject = this.lexer.next();
      while ((subject != null ? subject.type : void 0) === "linefeed") {
        subject = this.lexer.next();
      }
      return this.expr(subject);
    };

    Parser.prototype.expr = function(subject) {
      return this.block(subject) || this["function"](subject) || this.assignment(subject) || subject;
    };

    Parser.prototype.block = function(subject) {
      var n, _ref;
      if ((subject != null ? subject.type : void 0) === "block") {
        return {
          type: "block",
          source: subject.source,
          tracking: {
            start: subject.tracking.start,
            end: subject.tracking.end
          }
        };
      }
      if ((subject != null ? subject.type : void 0) === "linefeed") {
        if (((_ref = this.lexer.peek()) != null ? _ref.type : void 0) === "block") {
          n = this.lexer.next();
          return {
            type: "block",
            source: n.source,
            tracking: {
              start: subject.tracking.start,
              end: n.tracking.end
            }
          };
        }
      }
    };

    Parser.prototype["function"] = function(subject) {
      var node;
      if ((subject != null ? subject.type : void 0) === "function") {
        node = this.expr(this.lexer.next());
        return {
          type: "function",
          body: node,
          tracking: {
            start: subject.tracking.start,
            end: node.tracking.end
          }
        };
      }
    };

    Parser.prototype.assignment = function(subject) {
      return this.property_assignment(subject) || this.local_assignment(subject);
    };

    Parser.prototype.property_assignment = function(subject) {
      var n, node;
      if ((subject != null ? subject.type : void 0) === "symbol") {
        n = this.lexer.peek();
        if ((n != null ? n.token : void 0) === ":") {
          node = this.expr(this.lexer.next(2));
          return {
            type: "property_assignment",
            symbol: subject.token,
            value: node,
            tracking: {
              start: subject.tracking.start,
              end: node.tracking.end
            }
          };
        }
      }
      return null;
    };

    Parser.prototype.local_assignment = function(subject) {
      var n, node;
      if ((subject != null ? subject.type : void 0) === "symbol") {
        n = this.lexer.peek();
        if ((n != null ? n.token : void 0) === "=") {
          node = this.expr(this.lexer.next(2));
          return {
            type: "assignment",
            symbol: subject.token,
            value: node,
            tracking: {
              start: subject.tracking.start,
              end: node.tracking.end
            }
          };
        }
      }
    };

    return Parser;

  })(Cursor);

}).call(this);

});

require.define("/Cursor.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.3.3
(function() {
  var Cursor,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Cursor = (function() {

    function Cursor() {
      this.prev = __bind(this.prev, this);

      this.peek = __bind(this.peek, this);

      this.back = __bind(this.back, this);

      this.next = __bind(this.next, this);

      this.all = __bind(this.all, this);
      this.index = 0;
    }

    Cursor.prototype.all = function() {
      var t, _results;
      _results = [];
      while (t = this.next()) {
        _results.push(t);
      }
      return _results;
    };

    Cursor.prototype.next = function(i) {
      if (i == null) {
        i = 1;
      }
      return this.at((this.index += i) - 1);
    };

    Cursor.prototype.back = function(i) {
      if (i == null) {
        i = 1;
      }
      return this.at((this.index -= i) - 1);
    };

    Cursor.prototype.peek = function(i) {
      if (i == null) {
        i = 1;
      }
      return this.at((this.index + i) - 1);
    };

    Cursor.prototype.prev = function(i) {
      if (i == null) {
        i = 1;
      }
      return this.at((this.index - i) - 1);
    };

    return Cursor;

  })();

  module.exports = Cursor;

}).call(this);

});

require.define("/browser.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.3.3
(function() {

  window.imto = {
    Interpreter: require('./interpreter'),
    Lexer: require('./lexer')
  };

}).call(this);

});
require("/browser.js");
})();
