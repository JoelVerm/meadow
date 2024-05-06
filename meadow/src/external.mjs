import { createSignal, createEffect } from 'https://cdn.skypack.dev/solid-js'

export function server_signal({ value, name }) {
    const constructor = value.constructor
    const [signal, setSignal] = createSignal(value)
    let last = value
    createEffect(() => {
        let value = signal()
        if (value === last) return
        fetch(`server-signal/${name}/${value}`)
            .then(res => res.text())
            .then(text => {
                let newValue = constructor(text)
                last = newValue
                setSignal(newValue)
            })
    })
    return [signal, setSignal]
}
