const ReactServer = require('react-dom/server')
const React = require('react')
const readline = require('readline')

require('babel-polyfill')
require('babel-register')

process.stdin.on('end', () => {
  process.exit()
})

function makeHtml(body) {
  try {
    const componentPath = body.path
    const props = body.props

    const component = require(componentPath)
    const markup = ReactServer.renderToString(
      React.createElement(component.default, props)
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
  process.stdout.write(JSON.stringify(result))
})
