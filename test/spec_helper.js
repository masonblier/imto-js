var util = require("util");
var chai = require("chai");
var sinonChai = require("sinon-chai");

global.sinon = require("sinon");

chai.use(sinonChai);
chai.should();

var inspect = require('util').inspect;

global.pp = function(obj) {
  console.log("------------");
  console.log(inspect(obj, true, 4, true));
};
global.p = function(node) {
  process.stdout.write("============\n"+node+"\n");
};