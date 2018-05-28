const ReactServer = require('react-dom/server')
const React = require('react')
const ReactDOM = require('react-dom')
const readline = require('readline')

require('babel-polyfill')
require('babel-register')

function deleteCache(componentPath) {
  if (
    process.env.NODE_ENV !== 'production' &&
    require.resolve(componentPath) in require.cache
  ) {
    delete require.cache[require.resolve(componentPath)]
  }
}

function makeHtml({path, props}) {
  try {
    const componentPath = path

    // remove from cache in non-production environments
    // so that we can see changes
    deleteCache(componentPath)

    const component = require(componentPath)
    const element = component.default ? component.default : component
    const createdElement = React.createElement(element, props)

    const markup = ReactServer.renderToString(createdElement)
    const stringProps = JSON.stringify(props).replace(/"/g, '&quot;')

    const html = `<div data-rendered data-component="${
      element.name
    }" data-props="${stringProps}">${markup}</div>`

    const response = {
      error: null,
      markup: html,
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

function startServer() {
  process.stdin.on('end', () => {
    process.exit()
  })

  const readLineInterface = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false,
  })

  readLineInterface.on('line', line => {
    input = JSON.parse(line)
    result = makeHtml(input)
    jsonResult = JSON.stringify(result)
    process.stdout.write(jsonResult)
  })
}

/**
 * Hydrates react components that had HTML created from server.
 * Looks for divs with 'data-rendered' attributes. Gets component
 * name from the 'data-component' attribute and props from the
 * 'data-props' attribute.
 * @param {Function} componentMapper - A function that takes in a name and returns the component
 */
function hydrateClient(componentMapper) {
  const serverRenderedComponents = document.querySelectorAll('[data-rendered]')

  for (const serverRenderedComponent of serverRenderedComponents) {
    const component = componentMapper(serverRenderedComponent.dataset.component)
    const props = JSON.parse(serverRenderedComponent.dataset.props)
    const element = React.createElement(component, props)

    ReactDOM.hydrate(element, serverRenderedComponent)
  }
}

module.exports = {startServer, hydrateClient}

if (require.main === module) {
  startServer()
}
