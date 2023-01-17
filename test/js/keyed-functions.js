const uuid = require('uuid/v4')

function hello(name) {
  return `Hello, ${name}!`
}

function add(a, b) {
  return a + b
}

function sub(a, b) {
  return a - b
}

function throwTypeError() {
  throw new TypeError('oops')
}

function getBytes(size) {
  return Buffer.alloc(size)
}

class Unserializable {
  constructor() {
    this.circularRef = this
  }
}

function getIncompatibleReturnValue() {
  return new Unserializable()
}

function getArgv() {
  return process.argv
}

function getEnv() {
  return process.env
}

function logsSomething() {
  console.log("Something")
  process.stdout.write("something else")
  return 42
}

function returnUTF8String() {
  return {lang1: "中文", lang2: "hełło"}
}

module.exports = {
  uuid,
  hello,
  math: { add, sub },
  throwTypeError,
  getBytes,
  getIncompatibleReturnValue,
  getArgv,
  getEnv,
  logsSomething,
  returnUTF8String
}
