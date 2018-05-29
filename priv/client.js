import React from 'react'
import ReactDOM from 'react-dom'

/**
 * Hydrates react components that had HTML created from server.
 * Looks for divs with 'data-rendered' attributes. Gets component
 * name from the 'data-component' attribute and props from the
 * 'data-props' attribute.
 * @param {Function} componentMapper - A function that takes in a name and returns the component
 */
export function hydrateClient(componentMapper) {
  const serverRenderedComponents = document.querySelectorAll('[data-rendered]')

  for (const serverRenderedComponent of serverRenderedComponents) {
    const component = componentMapper(serverRenderedComponent.dataset.component)
    const props = JSON.parse(serverRenderedComponent.dataset.props)
    const element = React.createElement(component, props)

    ReactDOM.hydrate(element, serverRenderedComponent)
  }
}
