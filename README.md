# CarbonPhoenix

Phoenix LiveView function components for the
[Carbon Design System web components](https://web-components.carbondesignsystem.com/).

* `CarbonPhoenix.CoreComponents` - Phoenix-style core components (`flash`, `button`,
  `input`, `header`, `table`, `list`, `icon`) rendered with Carbon. Every one
  accepts a `carbon={%{...}}` map for further Carbon options.
* `CarbonPhoenix.WebComponents` - one generated component for **every**
  Carbon component and **every** option in the storybook (`<Carbon.modal>`,
  `<Carbon.tile>`, ...), with typed and documented assigns. Regenerate with
  `npm install && npm run generate`.
* `CarbonPhoenix.Icons` - the Carbon icon set, read from the `@carbon/icons`
  npm package at compile time (nothing is vendored in this repo).
* `priv/static/carbon_phoenix.js` - the `CarbonEvents` LiveView hook that
  forwards Carbon DOM events to the server.

## Installation

1. Add the dependency (git or Hex):

   ```elixir
   {:carbon_phoenix, github: "nyannus/carbon_phoenix"}
   # or {:carbon_phoenix, "~> 0.1"}
   ```

2. Install the Carbon npm packages in your app's `assets` directory. They are
   not bundled so you control the versions:

   ```sh
   npm install --prefix assets @carbon/web-components @carbon/styles @carbon/icons
   ```

   Add `"cmd npm install --prefix assets"` to your `assets.setup` alias.

   `@carbon/icons` is read by Elixir when `carbon_phoenix` compiles, so run npm
   *before* compiling the dep (`deps.get`, `assets.setup`, compile). If it was
   missing, run `mix deps.compile carbon_phoenix --force`. The directory can be
   overridden with `CARBON_ICONS_PATH=/path/to/@carbon/icons/svg/32`.

3. esbuild finds the dep's JS through `NODE_PATH`, which the default Phoenix
   config already points at `deps`.

4. In `assets/js/app.js`:

   ```js
   import "@carbon/web-components/es/index.js"   // or import single components
   import "@carbon/styles/css/styles.css"        // theme tokens + IBM Plex
   import {CarbonEvents} from "carbon_phoenix"

   const liveSocket = new LiveSocket("/live", Socket, {
     hooks: {...colocatedHooks, CarbonEvents},
     ...
   })
   ```

   Importing the CSS makes esbuild emit `priv/static/assets/js/app.css`; link it
   from your root layout.

5. Import the components in `my_app_web.ex` (`html_helpers`):

   ```elixir
   import CarbonPhoenix.CoreComponents
   alias CarbonPhoenix.WebComponents, as: Carbon
   ```

## Usage

```heex
<.button navigate={~p"/"} kind="tertiary" icon="home">Home</.button>
<.input field={@form[:email]} type="email" helper_text="We never share it" />
<Carbon.modal id="m" open={@open} on_closed="close">
  <Carbon.modal_header>
    <Carbon.modal_heading>Hi</Carbon.modal_heading>
  </Carbon.modal_header>
</Carbon.modal>
```

Only HTML attributes are supported (not JS-only properties). Named slots are
filled with `slot="name"` on the child. Component events are `on_*` assigns
holding a LiveView event name (the element needs an `id`). See the
"Events, slots and forms" guide.

## License

Apache-2.0 (Carbon web components and icons are Apache-2.0 as well).
