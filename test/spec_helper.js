var util = require("util");
var chai = require("chai");
var sinonChai = require("sinon-chai");

global.sinon = require("sinon");

chai.use(sinonChai);
chai.should();

global.pp = function(obj) { 
  console.log("============");
  console.log(util.inspect(obj, true, 4, true));
};
