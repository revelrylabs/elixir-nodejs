const path = require('path')
const readline = require('readline')
const { NODE_PATH } = process.env
const WRITE_CHUNK_SIZE = parseInt(process.env.WRITE_CHUNK_SIZE, 10)

function rewritePath(oldPath) {
  return oldPath
  const [_1, _2, relative, name] = oldPath.match(/^((\.\.?)\/)?(.*)$/)

  if (relative) {
    return path.join(NODE_PATH, relative, name)
  }

  return path.join(NODE_PATH, 'node_modules', name)
}

function requireModule(modulePath) {
  const newPath = rewritePath(modulePath)

  // When not running in production mode, refresh the cache on each call.
  if (process.env.NODE_ENV !== 'production') {
    delete require.cache[require.resolve(newPath)]
  }

  return require(newPath)
}

function getAncestor(parent, [key, ...keys]) {
  if (typeof key === 'undefined') {
    return parent
  }

  return getAncestor(parent[key], keys)
}

function requireModuleFunction([modulePath, ...keys]) {
  const mod = requireModule(modulePath)

  return getAncestor(mod, keys)
}

async function callModuleFunction(moduleFunction, args) {
  const fn = requireModuleFunction(moduleFunction)
  const returnValue = fn(...args)

  if (returnValue instanceof Promise) {
    return await returnValue
  }

  return returnValue
}

async function getResponse(string) {
  try {
    const [moduleFunction, args] = JSON.parse(string)
    const result = await callModuleFunction(moduleFunction, args)

    return JSON.stringify([true, result])
  } catch ({ message, stack }) {
    return JSON.stringify([false, `${message}\n${stack}`])
  }
}

async function onLine(string) {
  const buffer = Buffer.from(`${await getResponse(string)}\n`)

  for (let i = 0; i < buffer.length; i += WRITE_CHUNK_SIZE) {
    let chunk = buffer.slice(i, i + WRITE_CHUNK_SIZE)

    process.stdout.write(chunk)
  }
}

function startServer() {
  process.stdin.on('end', () => process.exit())

  const readLineInterface = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false,
  })

  readLineInterface.on('line', onLine)
}

module.exports = { startServer }

if (require.main === module) {
  startServer()
}
