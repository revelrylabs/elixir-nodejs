export { v4 as uuid } from 'uuid'

export function hello(name) {
  return `Hello, ${name}!`
}

export function add(a, b) {
  return a + b
}

export async function echo(x, delay = 1000) {
  return new Promise((resolve) => setTimeout(() => resolve(x), delay))
}