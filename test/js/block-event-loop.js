// Blocks the event loop for `ms` milliseconds.
module.exports = (ms) => {
  const end = Date.now() + ms
  while (Date.now() < end) {}
  return 'done'
}
