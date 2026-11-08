# Events, slots and forms

## Events

Carbon components notify you of user actions with DOM events (a modal closing,
a tab being selected, ...). Every component documents these as `on_*`
assigns that take a LiveView event name:

```heex
<Carbon.modal id="confirm" open={@confirm_open} on_closed="close_confirm">
  ...
</Carbon.modal>
```

```elixir
def handle_event("close_confirm", _params, socket) do
  {:noreply, assign(socket, confirm_open: false)}
end
```

The element needs an `id`. The event payload contains

| key | value |
| --- | --- |
| `"id"` | the element id |
| `"event"` | the underlying DOM event name |
| `"value"` | the element's `value`, if it has one |
| `"checked"` | the element's `checked` state, if it has one |
| `"detail"` | the event's `detail`, made JSON safe |

To send the event to a LiveComponent, add `phx-target={@myself}`.

This requires the `CarbonEvents` hook from the `carbon_phoenix` npm entry,
see the README.

## Slots

Child content is rendered in the default slot. Carbon components with named
slots take them by a `slot` attribute on the child:

```heex
<Carbon.tile>
  <Carbon.heading slot="title">Hello</Carbon.heading>
</Carbon.tile>
```

## Forms

Use `CarbonPhoenix.CoreComponents.input/1` inside `<.form>`. It picks the
matching Carbon control from `type` and shows changeset errors:

```heex
<.form for={@form} id="user-form" phx-change="validate" phx-submit="save">
  <.input field={@form[:name]} label="Name" />
  <.input field={@form[:role]} type="select" options={["Admin": "admin", "User": "user"]} />
  <.input field={@form[:newsletter]} type="toggle" label="Newsletter" />
  <.button type="submit">Save</.button>
</.form>
```

For controls without a `type`, use the matching `Carbon.*` component and put a
`name` on it. Carbon form controls take part in form submission.
