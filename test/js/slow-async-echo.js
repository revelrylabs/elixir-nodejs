module.exports = async function echo(x, delay = 1000) {
  return new Promise((resolve) => setTimeout(() => resolve(x), delay))
}
