// Generates lib/carbon_phoenix/web_components.ex from the custom elements
// manifest and type definitions shipped with @carbon/web-components.
//
//   npm install && npm run generate
//
import {readFileSync, writeFileSync, readdirSync, statSync} from "node:fs"
import {fileURLToPath} from "node:url"
import {dirname, join} from "node:path"

const here = dirname(fileURLToPath(import.meta.url))
const pkgDir = join(here, "../node_modules/@carbon/web-components")
const outPath = join(here, "../lib/carbon_phoenix/web_components.ex")
const manifest = JSON.parse(readFileSync(join(pkgDir, "custom-elements.json"), "utf8"))

// ---- resolve TypeScript enums (BUTTON_KIND -> ["primary", ...]) ----------
const enums = {}
function walk(dir) {
  for (const f of readdirSync(dir)) {
    const p = join(dir, f)
    if (statSync(p).isDirectory()) walk(p)
    else if (f.endsWith(".d.ts")) {
      const src = readFileSync(p, "utf8")
      for (const m of src.matchAll(/export declare enum (\w+) \{([\s\S]*?)\n\}/g)) {
        const body = m[2].replace(/\/\*[\s\S]*?\*\//g, "")
        const vals = [...body.matchAll(/=\s*"([^"]*)"/g)].map(x => x[1])
        if (vals.length) enums[m[1]] = vals
      }
    }
  }
}
walk(join(pkgDir, "es"))

function allowedValues(type) {
  if (!type) return null
  const members = type.split("|").map(s => s.trim()).filter(s => s && s !== "undefined" && s !== "null")
  if (!members.length) return null
  const out = []
  for (const m of members) {
    const lit = m.match(/^"([^"]*)"$/)
    if (lit) out.push(lit[1])
    else if (enums[m]) out.push(...enums[m])
    else return null
  }
  return [...new Set(out)]
}

// ---- helpers -----------------------------------------------------------
const RESERVED = new Set(["rest", "inner_block", "__changed__", "__given__"])
// Phoenix.Component / Kernel functions that would clash with generated names
const str = s => JSON.stringify(s ?? "").replace(/#\{/g, "\\#{")
const snake = s => s.replace(/([a-z0-9])([A-Z])/g, "$1_$2").replace(/-/g, "_").toLowerCase()
const balance = s => ((s.match(/`/g) || []).length % 2 ? s.replace(/`/g, "") : s)
const strip = s => balance(s ?? "").replace(/`?<?cds-([a-z0-9-]+)>?`?/g, (_, n) => `\`Carbon.${snake(n)}\``)
const sigil = s => strip(s).replace(/"""/g, "'''").split("\n").map(l => ("  " + l).trimEnd()).join("\n")
const typeOf = t => ((t || "").toLowerCase() === "boolean" ? ":boolean" : (t || "").toLowerCase() === "string" ? ":string" : ":any")
const GROUPS = {
  date: "Date picker", combo: "Combo box", radio: "Radio button", text: "Text input", number: "Number input",
  password: "Password input", file: "File uploader", side: "Side panel", page: "Page header", full: "Full page error",
  tree: "Tree view", content: "Content switcher", code: "Code snippet", copy: "Copy button", data: "Data table",
  inline: "Inline loading", multi: "Multi select", overflow: "Overflow menu", progress: "Progress", structured: "Structured list",
  toggle: "Toggle", ui: "UI shell", user: "User avatar", skip: "Skip to content", menu: "Menu", header: "UI shell",
}
const title = s => s.charAt(0).toUpperCase() + s.slice(1)

const tags = manifest.tags.filter(t => /^cds-/.test(t.name)).sort((a, b) => a.name.localeCompare(b.name))
const out = []
const seen = new Set()

for (const tag of tags) {
  const bare = tag.name.replace(/^cds-/, "")
  const fn = snake(bare)
  if (seen.has(fn)) continue
  seen.add(fn)
  const first = bare.split("-")[0]
  const group = GROUPS[first] || title(first)

  // attributes
  const attrs = []
  const names = new Set()
  for (const a of tag.attributes || []) {
    const key = snake(a.name)
    if (RESERVED.has(key) || names.has(key)) continue
    names.add(key)
    attrs.push({key, name: a.name, type: typeOf(a.type), values: allowedValues(a.type), desc: a.description, rawType: a.type, def: a.default})
  }

  // events -> on_<name> attributes
  const events = []
  for (const e of tag.events || []) {
    if (!e.name.startsWith("cds-")) continue
    let short = e.name.startsWith(tag.name + "-") ? e.name.slice(tag.name.length + 1) : e.name.slice(4)
    const key = "on_" + snake(short)
    if (names.has(key)) continue
    names.add(key)
    events.push({key, name: e.name, desc: (e.description || "").replace(/\n/g, " ")})
  }

  const example = [
    `<Carbon.${fn}${events.length ? ` id="my-${bare}"` : ""}${events.length ? ` ${events[0].key}="my_event"` : ""}>`,
    "  ...",
    `</Carbon.${fn}>`,
  ].join("\n")

  const doc = [
    strip(tag.description || `The ${bare.replace(/-/g, " ")} component.`),
    "",
    `Renders the Carbon \`${bare.replace(/-/g, " ")}\` web component.`,
    "",
    "## Example",
    "",
    "```heex",
    example,
    "```",
    "",
    "Child content is rendered inside the component. To fill a named slot of the",
    "component, set `slot=\"name\"` on the child element.",
    ...(events.length
      ? [
          "",
          "## Events",
          "",
          "Each `on_*` attribute takes the name of a LiveView event and requires an `id`.",
          "The LiveView receives `%{\"detail\" => ..., \"value\" => ..., \"id\" => ...}`.",
          "",
          ...events.map(e => `  * \`${e.key}\` - ${strip(e.desc)}`),
        ]
      : []),
  ].join("\n")

  out.push(`  @${fn}_attrs [${attrs.map(a => `{:${a.key}, ${str(a.name)}}`).join(", ")}]`)
  out.push(`  @${fn}_events [${events.map(e => `{:${e.key}, ${str(e.name)}}`).join(", ")}]`)
  out.push("")
  out.push(`  @doc group: ${str(group)}`)
  out.push(`  @doc ~S"""\n${sigil(doc)}\n  """`)
  out.push(`  attr :rest, :global, doc: "any additional HTML attributes, e.g. \`class\`, \`id\`, \`slot\`, \`phx-*\`"`)
  for (const a of attrs) {
    const docParts = [
      strip(a.desc || ""),
      a.values ? "" : a.rawType && !/^(boolean|string|number)( \| (undefined|null))?$/i.test(a.rawType) ? `Type: \`${a.rawType}\`.` : "",
      a.def !== undefined && a.def !== "" ? `Carbon default: \`${strip(a.def)}\`.` : "",
    ].filter(Boolean).join(" ").replace(/\s+/g, " ")
    const values = a.values ? `, values: [${a.values.map(str).join(", ")}]` : ""
    const type = a.values ? ":any" : a.type
    out.push(`  attr :${a.key}, ${type}${a.values ? "" : ", default: nil"}${values}, doc: ${str(docParts)}`)
  }
  for (const e of events) out.push(`  attr :${e.key}, :string, default: nil, doc: ${str("LiveView event name, sent when the component emits its \"" + e.name.replace(/^cds-/, "").replace(/-/g, " ") + "\" event. " + strip(e.desc))}`)
  out.push(`  slot :inner_block`)
  out.push(`  def ${fn}(assigns) do`)
  out.push(`    assigns = assign(assigns, :carbon_attrs, build(assigns, ${JSON.stringify(tag.name)}, @${fn}_attrs, @${fn}_events))`)
  out.push(`    ~H"""`)
  out.push(`    <${tag.name} {@carbon_attrs} {@rest}>{render_slot(@inner_block)}</${tag.name}>`)
  out.push(`    """`)
  out.push(`  end`)
  out.push("")
}

const header = `# This file is GENERATED by scripts/generate.mjs from
# @carbon/web-components ${manifest.version || ""}. Do not edit by hand.
defmodule CarbonPhoenix.WebComponents do
  @moduledoc """
  One function component for every Carbon Design System web component,
  generated from the package's metadata, so every option shown in the
  [Carbon web components storybook](https://web-components.carbondesignsystem.com/)
  is an assign.

  Alias the module as \`Carbon\` (see the README) and call components by their
  storybook name in snake case:

      <Carbon.modal id="confirm" open={@open} size="sm" on_closed="close_modal">
        <Carbon.modal_header>
          <Carbon.modal_heading>Are you sure?</Carbon.modal_heading>
        </Carbon.modal_header>
        <Carbon.modal_body>This cannot be undone.</Carbon.modal_body>
      </Carbon.modal>

  ## Conventions

    * **Assigns** are snake_cased versions of the component's attributes
      (\`batch-action\` becomes \`batch_action\`). Booleans are present or absent;
      \`nil\` omits the attribute so Carbon's own default applies. Lists and maps
      are JSON encoded. Attributes with a fixed set of choices list them as
      \`values\`.
    * **Events** are \`on_*\` assigns holding a LiveView event name:
      \`on_closed="close_modal"\` sends \`"close_modal"\` to the LiveView when the
      modal closes. The element needs an \`id\`. Add \`phx-target\` to send to a
      component instead. The payload is
      \`%{"id" => ..., "event" => ..., "value" => ..., "checked" => ..., "detail" => ...}\`.
    * **Slots**: child content is rendered inside the component. Named slots are
      filled with \`slot="name"\` on the child.
    * Everything else (\`class\`, \`id\`, \`style\`, \`phx-*\`, \`data-*\`, ...) is passed
      through.

  Events require the \`CarbonEvents\` hook, see the README.

  Components that are tuned for Phoenix forms and tables (\`button\`, \`input\`,
  \`table\`, ...) live in \`CarbonPhoenix.CoreComponents\`.
  """
  use Phoenix.Component

  # \`Carbon.link\` and \`Carbon.form\` are defined here, so do not import the
  # Phoenix functions of the same name.
  import Phoenix.Component, except: [link: 1, form: 1]

  @doc false
  def build(assigns, tag, specs, events) do
    attrs =
      for {key, name} <- specs,
          value = Map.get(assigns, key),
          value != nil,
          into: %{},
          do: {name, encode(value)}

    on = for {key, event} <- events, name = Map.get(assigns, key), name != nil, into: %{}, do: {event, name}

    if map_size(on) > 0 do
      unless assigns.rest[:id] do
        raise ArgumentError, "Carbon.#{String.replace(tag, "cds-", "")}: on_* events require an \`id\`"
      end

      Map.merge(attrs, %{"phx-hook" => "CarbonEvents", "data-carbon-on" => Jason.encode!(on)})
    else
      attrs
    end
  end

  defp encode(value) when is_list(value) or (is_map(value) and not is_struct(value)),
    do: Jason.encode!(value)

  defp encode(value), do: value

`
writeFileSync(outPath, header + out.join("\n").replace(/\n{3,}/g, "\n\n") + "end\n")
console.log(`generated ${seen.size} components, ${Object.keys(enums).length} enums -> ${outPath}`)
