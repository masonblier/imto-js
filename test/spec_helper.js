var util = require("util");
var chai = require("chai");
var sinonChai = require("sinon-chai");

global.sinon = require("sinon");

chai.use(sinonChai);
chai.should();
