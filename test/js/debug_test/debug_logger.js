// This file outputs debugging information to stdout
console.log("Debug message: Module loading");
console.debug("Debug message: Initializing module");

module.exports = function testFunction(input) {
  console.log(`Debug message: Function called with input: ${input}`);
  console.debug("Debug message: Processing input");
  
  return `Processed: ${input}`;
};
