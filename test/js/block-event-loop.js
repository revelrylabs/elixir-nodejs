// Busy-waits on the main thread for the given number of milliseconds.
// Used to simulate CPU-bound JavaScript that blocks the Node.js event loop.
module.exports = (ms) => {
  const end = Date.now() + ms
  while (Date.now() < end) {}
  return 'done'
}
