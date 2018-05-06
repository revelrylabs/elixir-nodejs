const ReactServer = require('react-dom/server')
const React = require('react')
const readline = require('readline')

require('babel-polyfill')
require('babel-register')

process.stdin.on('end', () => {
  process.exit()
})

function makeHtml({path, props}) {
  try {
    const componentPath = path

    // remove from cache in non-production environments
    // so that we can see changes
    if (
      process.env.NODE_ENV != 'production' &&
      require.resolve(componentPath) in require.cache
    ) {
      delete require.cache[require.resolve(componentPath)]
    }

    const component = require(componentPath)
    const element = component.default ? component.default : component

    const markup = ReactServer.renderToString(
      React.createElement(element, props)
    )

    const response = {
      error: null,
      markup,
    }

    return response
  } catch (err) {
    const response = {
      error: {
        type: err.constructor.name,
        message: err.message,
        stack: err.stack,
      },
      markup: null,
    }

    return response
  }
}

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false,
})

rl.on('line', function(line) {
  input = JSON.parse(line)
  result = makeHtml(input)
  json_result = JSON.stringify(result)
  process.stdout.write(json_result)
})
