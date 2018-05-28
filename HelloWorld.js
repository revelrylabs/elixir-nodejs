import React, {Component, createElement} from 'react'

class HelloWorld extends Component {
  render() {
    const {name} = this.props

    return <div>Hello {name}</div>
  }
}

export default HelloWorld
