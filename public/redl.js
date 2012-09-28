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
      var l, n, r, _results;
      l = Lexer(code);
      r = [];
      _results = [];
      while (n = l.next()) {
        _results.push(n);
      }
      return _results;
    };

    Interpreter.prototype.parse = function(code) {
      var n, p, _results;
      p = Parser(Lexer(code));
      _results = [];
      while (n = p.next()) {
        _results.push(n);
      }
      return _results;
    };

    Interpreter.prototype["eval"] = function(code) {
      return this.context.myvar = "1";
    };

    Interpreter.prototype.print = function(list, indent) {
      var head, node;
      if (indent == null) {
        indent = "";
      }
      return ((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = list.length; _i < _len; _i++) {
          node = list[_i];
          head = "" + indent + "(" + (clc.green(node.type));
          if (node.type === "block") {
            _results.push("" + head + "\n" + (this.print(node.tree, indent + "  ")) + "\n" + indent + ")");
          } else if (node.type === "function") {
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
      }).call(this)).join("\n");
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
  var Lexer, OPERATORS, WHITESPACE,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  WHITESPACE = [' ', '\t'];

  OPERATORS = ['=', '+', '-', '*', '/', '<', '>', '%', '&', '(', ')', '[', ']', '^', ':', '?', '.'];

  Lexer = function(str) {
    var LexerClass;
    LexerClass = (function() {
      var c, formatBlockSource, input, m, memos, next_token, replaceSpecials, special;

      c = 0;

      m = -1;

      input = '';

      special = [];

      memos = [];

      function LexerClass(str) {
        c = 0;
        input = str;
        replaceSpecials();
      }

      LexerClass.prototype.all = function() {
        var t, _results;
        _results = [];
        while (t = this.next()) {
          _results.push(t);
        }
        return _results;
      };

      LexerClass.prototype.next = function(i) {
        var o;
        if (i == null) {
          i = 1;
        }
        o = m + i;
        while (m < o) {
          if (!memos[m += 1]) {
            memos[m] = next_token();
          }
        }
        return memos[m];
      };

      LexerClass.prototype.back = function(i) {
        if (i == null) {
          i = 1;
        }
        m -= i;
        return memos[m];
      };

      LexerClass.prototype.peek = function(i) {
        var o;
        if (i == null) {
          i = 1;
        }
        o = m + i;
        while (m < o) {
          this.next();
        }
        m = o - i;
        return memos[o];
      };

      LexerClass.prototype.prev = function(i) {
        if (i == null) {
          i = 1;
        }
        return memos[m - i];
      };

      replaceSpecials = function() {
        var d, i, idx, imtch, indent, k, l, lines, marker, match, p, paramList, params, submatch, token, _i, _len, _results;
        lines = input.split('\n');
        indent = '';
        while ((!/\S/.test(lines[0])) && lines.length > 1) {
          lines.splice(0, 1);
        }
        if (imtch = /^\s+/.exec(lines[0] && (imtch != null))) {
          indent = imtch[0];
        }
        i = 0;
        l = -1;
        while (i <= lines.length) {
          while (i < lines.length && (lines[i].indexOf(indent === 0)) && /^\s/.test(lines[i].substr(indent.length))) {
            if (l === -1) {
              l = i;
            }
            i++;
          }
          if (l >= 0) {
            str = lines.splice(l, i - l).join('\n');
            idx = special.length;
            lines.splice(l, 0, "{" + idx + "}");
            special[idx] = {
              type: 'block',
              token: str,
              'source': formatBlockSource(str)
            };
            i = l;
            l = -1;
          }
          i++;
        }
        input = lines.join('\n');
        i = 0;
        d = 0;
        l = 0;
        while (i < input.length) {
          if (input[i] === '{') {
            if (d === 0) {
              l = i;
            }
            d += 1;
          } else if (input[i] === '}') {
            d -= 1;
            if (d === 0) {
              token = input.substr(l, i - l + 1);
              if (/^(\s*)\{([0-9])+\}(\s*)$/.test(token)) {
                i++;
                continue;
              } else if ((imtch = /^\{(\s*)\{([0-9])+\}(\s*)\}$/.exec(token)) && (imtch != null)) {
                marker = '{' + imtch[2] + '}';
                input = input.substr(0, l) + marker + input.substr(i + 1);
              } else {
                k = special.length;
                marker = "{" + k + "}";
                input = input.substr(0, l) + marker + input.substr(i + 1);
                special[k] = {
                  type: 'block',
                  'token': token,
                  'source': formatBlockSource(token)
                };
              }
              i = l + marker.length;
            }
            if (d <= -1) {
              throw 'parser stack index out of bounds';
            }
          }
          i += 1;
        }
        if (d > 0) {
          throw 'parser stack unbalanced';
        }
        _results = [];
        while ((match = /\(((?:[,\t ]*[a-zA-Z_][a-zA-Z0-9_]*)+[\t ]*)?\)[\t ]*[=-]>/.exec(input)) !== null) {
          i = special.length;
          input = input.replace(match[0], "{" + i + "}");
          paramList = [];
          submatch = /\((.*)\)/.exec(match[0]);
          params = /,/.test(submatch[1]) ? submatch[1].split(',') : [];
          for (_i = 0, _len = params.length; _i < _len; _i++) {
            p = params[_i];
            paramList.push(p.trim());
          }
          _results.push(special[i] = {
            type: 'function',
            'token': match[0],
            paramList: paramList
          });
        }
        return _results;
      };

      formatBlockSource = function(source) {
        var imtch, indent, line, lines, work;
        work = source;
        indent = '';
        if (work[0] === '{' && work[work.length - 1] === '}') {
          work = work.substr(1, work.length - 2);
        }
        lines = work.split('\n');
        while ((!/\S/.test(lines[0])) && lines.length > 1) {
          lines.splice(0, 1);
        }
        if ((imtch = /^\s+/.exec(lines[0])) && (imtch != null)) {
          indent = imtch[0];
        }
        work = ((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = lines.length; _i < _len; _i++) {
            line = lines[_i];
            _results.push(line.replace(indent, ''));
          }
          return _results;
        })()).join('\n');
        return work;
      };

      next_token = function() {
        var buffer, index, sym, token, value, x;
        if (c >= input.length) {
          return null;
        }
        x = input[c];
        c += 1;
        buffer = '';
        while (__indexOf.call(WHITESPACE, x) >= 0) {
          x = input[c];
          c += 1;
        }
        if (x === void 0) {
          return {
            type: 'none',
            token: ""
          };
        }
        if (x === '{') {
          while (true) {
            x = input[c];
            c++;
            if (!(c < input.length && x !== '}')) {
              break;
            }
            buffer += x;
          }
          index = parseInt(buffer);
          return special[index];
        }
        if (__indexOf.call(OPERATORS, x) >= 0) {
          while (true) {
            buffer += x;
            x = input[c];
            if (__indexOf.call(OPERATORS, x) < 0) {
              break;
            }
            c += 1;
            if (!(c < input.length)) {
              break;
            }
          }
          return {
            type: 'operator',
            token: buffer
          };
        }
        if (/([a-zA-Z_]|@|\.)/.test(x)) {
          token = '';
          while (true) {
            token += x;
            if (!(c < input.length)) {
              break;
            }
            x = input[c];
            if (!(x === '.' || /([a-zA-Z0-9_])/.test(x))) {
              break;
            }
            c++;
          }
          return {
            type: 'symbol',
            token: token
          };
        }
        if (/([0-9])/.test(x)) {
          value = '';
          while (true) {
            value += x;
            if (!(c < input.length && (x = input[c]))) {
              break;
            }
            if (!/([0-9]|\.)/.test(x)) {
              break;
            }
            c++;
          }
          return {
            type: 'literal',
            token: value,
            value: parseFloat(value)
          };
        }
        if (x === "'" || x === '"') {
          sym = x;
          value = '';
          while (true) {
            if (!(c < input.length)) {
              break;
            }
            x = input[c];
            c++;
            if (x === sym) {
              break;
            }
            value += x;
          }
          return {
            type: 'literal',
            token: sym + value + sym,
            value: value
          };
        }
        if (x === '\n') {
          return {
            type: 'linefeed',
            token: '\n'
          };
        }
        return {
          type: 'unknown'
        };
      };

      return LexerClass;

    })();
    return new LexerClass(str);
  };

  module.exports = Lexer;

}).call(this);

});

require.define("/parser.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.3.3
(function() {
  var Lexer, Parser;

  Lexer = require('./lexer');

  Parser = function(lexer) {
    var ParserClass;
    ParserClass = (function() {

      function ParserClass(lexer) {
        this.lexer = lexer;
      }

      ParserClass.prototype.all = function() {
        var n, _results;
        _results = [];
        while (n = this.next()) {
          _results.push(n);
        }
        return _results;
      };

      ParserClass.prototype.next = function() {
        var subject;
        subject = this.lexer.next();
        while ((subject != null ? subject.type : void 0) === "linefeed") {
          subject = this.lexer.next();
        }
        return this.expr(subject);
      };

      ParserClass.prototype.expr = function(subject) {
        return this.block(subject) || this["function"](subject) || this.parenclosure(subject) || this.assignment(subject) || subject;
      };

      ParserClass.prototype.parenclosure = function(subject) {
        var inner, _ref;
        if ((subject != null ? subject.token : void 0) === "(") {
          inner = this.expr(this.lexer.next());
          if (((_ref = this.lexer.peek()) != null ? _ref.token : void 0) === ")") {
            this.lexer.next();
            return inner;
          } else {
            throw new Error("Invalid syntax");
          }
        }
      };

      ParserClass.prototype.block = function(subject) {
        var n, _ref;
        if ((subject != null ? subject.type : void 0) === "block") {
          return {
            type: "block",
            tree: Parser(Lexer(subject.source)).all()
          };
        }
        if ((subject != null ? subject.type : void 0) === "linefeed") {
          if (((_ref = this.lexer.peek()) != null ? _ref.type : void 0) === "block") {
            n = this.lexer.next();
            return {
              type: "block",
              tree: Parser(Lexer(n.source)).all()
            };
          }
        }
      };

      ParserClass.prototype["function"] = function(subject) {
        if ((subject != null ? subject.type : void 0) === "function") {
          return {
            type: "function",
            body: this.expr(this.lexer.next())
          };
        }
      };

      ParserClass.prototype.assignment = function(subject) {
        return this.property_assignment(subject) || this.local_assignment(subject);
      };

      ParserClass.prototype.property_assignment = function(subject) {
        var n;
        if ((subject != null ? subject.type : void 0) === "symbol") {
          n = this.lexer.peek();
          if ((n != null ? n.token : void 0) === ":") {
            return {
              type: "property_assignment",
              symbol: subject.token,
              value: this.expr(this.lexer.next(2))
            };
          }
        }
        return null;
      };

      ParserClass.prototype.local_assignment = function(subject) {
        var n;
        if ((subject != null ? subject.type : void 0) === "symbol") {
          n = this.lexer.peek();
          if ((n != null ? n.token : void 0) === "=") {
            return {
              type: "assignment",
              symbol: subject.token,
              value: this.expr(this.lexer.next(2))
            };
          }
        }
      };

      return ParserClass;

    })();
    return new ParserClass(lexer);
  };

  module.exports = Parser;

}).call(this);

});

require.define("/browser.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.3.3
(function() {

  window.redl = {
    Interpreter: require('./interpreter'),
    Lexer: require('./lexer')
  };

}).call(this);

});
require("/browser.js");
})();
