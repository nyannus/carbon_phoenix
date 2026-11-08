defmodule CarbonPhoenix.Components do
  @moduledoc """
  Provides core UI components, built on the
  [Carbon Design System web components](https://web-components.carbondesignsystem.com/).

  The components in this module keep the usual Phoenix API (`flash/1`,
  `button/1`, `input/1`, `header/1`, `table/1`, `list/1`, `icon/1`) but render
  `cds-*` custom elements. They expose the most relevant Carbon options as
  regular assigns.

  Every one of them also accepts a `carbon` map. Its entries are rendered as
  extra attributes on the underlying Carbon element, which makes every
  attribute from the storybook reachable, e.g. `carbon={%{"helper-text" => "Hi"}}`.

  For a one-to-one wrapper of *every* Carbon web component and *every*
  attribute, see `CarbonPhoenix.WebComponents` (`<.cds_tile>`, `<.cds_modal>`, ...).

  References:

    * [Carbon web components](https://web-components.carbondesignsystem.com/) -
      the storybook with all components and their options.

    * [Carbon icons](https://carbondesignsystem.com/elements/icons/library/) -
      see `icon/1` for usage.

    * [Phoenix.Component](https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  # Spacing between stacked form fields
  @field_style "margin-block-end: var(--cds-spacing-05, 1rem)"

  ## Flash

  @flash_kinds [:info, :error, :success, :warning, :"info-square", :"warning-alt"]

  @doc """
  Renders flash notices as Carbon toast notifications.

  Place flashes inside a positioned container, see
  `your layout`s flash group`.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:success} timeout={5000} flash={@flash} />
      <.flash
        id="welcome-back"
        kind={:info}
        phx-mounted={show("#welcome-back") |> JS.remove_attribute("hidden")}
        hidden
      >
        Welcome Back!
      </.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: @flash_kinds, doc: "used for styling and flash lookup"
  attr :caption, :string, default: nil, doc: "optional caption shown below the message"
  attr :timeout, :integer, default: nil, doc: "milliseconds until the toast closes itself"
  attr :low_contrast, :boolean, default: false, doc: "use the low contrast toast variant"
  attr :hide_close_button, :boolean, default: false, doc: "hide the close button"

  attr :carbon, :map,
    default: %{},
    doc: "additional attributes for the `cds-toast-notification` element"

  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      {@rest}
    >
      <cds-toast-notification
        open
        kind={@kind}
        title={@title}
        subtitle={msg}
        caption={@caption}
        timeout={@timeout}
        low-contrast={@low_contrast}
        hide-close-button={@hide_close_button}
        {@carbon}
      >
      </cds-toast-notification>
    </div>
    """
  end

  ## Button

  @button_kinds ~w(primary secondary tertiary ghost danger danger--primary danger--tertiary danger--ghost danger-tertiary danger-ghost)
  @button_sizes ~w(xs sm md lg xl 2xl)

  @doc """
  Renders a Carbon button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" kind="danger">Delete</.button>
      <.button navigate={~p"/"} kind="tertiary" size="sm">Home</.button>
      <.button kind="ghost" icon="add" icon_only tooltip_text="Add">Add</.button>
  """
  attr :rest, :global,
    include:
      ~w(href navigate patch method download name value disabled type form formaction formmethod formtarget target rel hreflang ping autofocus)

  attr :kind, :string,
    default: nil,
    values: [nil | @button_kinds],
    doc: "the Carbon button kind, defaults to `primary`"

  attr :variant, :string,
    default: nil,
    doc: "alias of `kind`, kept for compatibility with generated Phoenix code"

  attr :size, :string, default: nil, values: [nil | @button_sizes]
  attr :expressive, :boolean, default: false, doc: "use the expressive button style"
  attr :selected, :boolean, default: false, doc: "selected state of icon-only ghost buttons"
  attr :icon, :string, default: nil, doc: "name of a Carbon icon, see `icon/1`"
  attr :icon_only, :boolean, default: false, doc: "render only the icon, label becomes tooltip"
  attr :tooltip_text, :string, default: nil
  attr :tooltip_position, :string, default: nil, values: [nil, "top", "right", "bottom", "left"]

  attr :tooltip_alignment, :string,
    default: nil,
    values: [nil, "start", "center", "end"]

  attr :danger_description, :string,
    default: nil,
    doc: "screen reader text for the danger kinds"

  attr :carbon, :map, default: %{}, doc: "additional attributes for the `cds-button` element"
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    assigns =
      assigns
      |> assign(:kind, kind_name(assigns.kind || assigns.variant))
      |> assign(:link, link_attrs(rest))

    ~H"""
    <cds-button
      kind={@kind}
      size={@size}
      isExpressive={@expressive}
      isSelected={@selected}
      tooltip-text={@tooltip_text}
      tooltip-position={@tooltip_position}
      tooltip-alignment={@tooltip_alignment}
      danger-description={@danger_description}
      class={@class}
      {@carbon}
      {@link}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} slot="icon" />
      <%= if @icon_only do %>
        <span class="cds--assistive-text">{render_slot(@inner_block)}</span>
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </cds-button>
    """
  end

  defp kind_name(nil), do: "primary"
  defp kind_name(kind), do: kind

  # `cds-button` renders the anchor inside its shadow root, so the LiveView
  # navigation bindings that `<.link>` would set are put on the host element.
  defp link_attrs(rest) do
    cond do
      rest[:navigate] ->
        %{
          "href" => rest[:navigate],
          "data-phx-link" => "redirect",
          "data-phx-link-state" => "push"
        }

      rest[:patch] ->
        %{"href" => rest[:patch], "data-phx-link" => "patch", "data-phx-link-state" => "push"}

      true ->
        %{}
    end
  end

  ## Input

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  Each type renders the matching Carbon form control:

  | type | Carbon element |
  | --- | --- |
  | `text`, `email`, `tel`, `url`, `color`, `month`, `week`, `datetime-local` | `cds-text-input` |
  | `password` | `cds-password-input` |
  | `number` | `cds-number-input` |
  | `search` | `cds-search` |
  | `textarea` | `cds-textarea` |
  | `select` | `cds-select` (`cds-multi-select` with `multiple`) |
  | `dropdown`, `combo-box`, `multi-select` | `cds-dropdown`, `cds-combo-box`, `cds-multi-select` |
  | `radio-group` | `cds-radio-button-group` |
  | `checkbox` | `cds-checkbox`, used exclusively for boolean values |
  | `toggle` | `cds-toggle`, boolean value |
  | `range` | `cds-slider` |
  | `date` | `cds-date-picker` |
  | `time` | `cds-time-picker` |
  | `file` | `cds-file-uploader` |
  | `hidden` | plain `<input type="hidden">` |

  For live file uploads, see `Phoenix.Component.live_file_input/1`.

  Options that are not available as assigns can be passed through the
  `carbon` map, which is rendered as attributes on the Carbon element.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" helper_text="We never share it" />
  <.input name="my-input" errors={["oh no!"]} />
  <.input field={@form[:age]} type="number" carbon={%{"min" => 0, "max" => 120}} />
  ```

  ## Select, dropdown, combo-box, multi-select and radio-group

  These types need `options` and optionally a `value` to mark which option
  should be preselected. Options may be plain values, `{label, value}`
  tuples, or `{group_label, options}` for grouped selects.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  <.input field={@form[:tags]} type="multi-select" options={@tags} />
  ```
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden range toggle dropdown
               combo-box multi-select radio-group)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox and toggle inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"

  attr :options, :list,
    doc: "the options for select, dropdown, combo-box, multi-select, radio-group"

  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :helper_text, :string, default: nil, doc: "help text shown below the input"
  attr :hide_label, :boolean, default: false, doc: "visually hide the label"
  attr :size, :string, default: nil, values: [nil, "sm", "md", "lg"], doc: "the Carbon input size"
  attr :warn, :boolean, default: false, doc: "show the warning state"
  attr :warn_text, :string, default: nil, doc: "text shown in the warning state"
  attr :inline, :boolean, default: false, doc: "use the inline layout where supported"
  attr :class, :any, default: nil, doc: "class added to the Carbon element"

  attr :carbon, :map,
    default: %{},
    doc: "additional attributes for the Carbon element, e.g. `%{\"enable-counter\" => true}`"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []
    multiple? = assigns.multiple or assigns.type == "multi-select"

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if multiple?, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: type} = assigns) when type in ["checkbox", "toggle"] do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div style={field_style()}>
      <input
        type="hidden"
        name={@name}
        value="false"
        disabled={@rest[:disabled]}
        form={@rest[:form]}
      />
      <cds-checkbox
        :if={@type == "checkbox"}
        id={@id}
        name={@name}
        value="true"
        checked={@checked}
        label-text={@label}
        {common(assigns)}
        {@carbon}
        {@rest}
      >
      </cds-checkbox>
      <cds-toggle
        :if={@type == "toggle"}
        id={@id}
        name={@name}
        value="true"
        toggled={@checked}
        label-text={@label}
        {common(assigns)}
        {@carbon}
        {@rest}
      >
      </cds-toggle>
    </div>
    """
  end

  def input(%{type: type} = assigns)
      when type in ["select", "dropdown", "combo-box", "multi-select"] do
    assigns =
      assigns
      |> assign(:tag, select_tag(type, assigns.multiple))
      |> assign(:selected, selected_values(assigns[:value]))
      |> assign(:items, normalize_options(assigns[:options] || []))

    assigns = assign(assigns, :attrs, select_attrs(assigns))

    ~H"""
    <div style={field_style()}>
      <.dynamic_tag tag_name={@tag} {@attrs}>
        <%= if @tag == "cds-select" do %>
          <cds-select-item :if={@prompt} value="" label={@prompt}></cds-select-item>
        <% end %>
        <%= for item <- @items do %>
          <.option_item tag={@tag} item={item} selected={@selected} />
        <% end %>
      </.dynamic_tag>
    </div>
    """
  end

  def input(%{type: "radio-group"} = assigns) do
    assigns =
      assigns
      |> assign(:selected, selected_values(assigns[:value]))
      |> assign(:items, normalize_options(assigns[:options] || []))

    ~H"""
    <div style={field_style()}>
      <cds-radio-button-group
        id={@id}
        name={@name}
        value={List.first(@selected)}
        legend-text={@label}
        {common(assigns)}
        {@carbon}
        {@rest}
      >
        <cds-radio-button
          :for={{:item, label, value} <- @items}
          label-text={label}
          value={value}
          checked={value in @selected}
        ></cds-radio-button>
      </cds-radio-button-group>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div style={field_style()}>
      <cds-textarea
        id={@id}
        name={@name}
        label={@label}
        value={Phoenix.HTML.Form.normalize_value("textarea", @value)}
        {common(assigns)}
        {@carbon}
        {@rest}
      >
      </cds-textarea>
    </div>
    """
  end

  def input(%{type: "range"} = assigns) do
    ~H"""
    <div style={field_style()}>
      <cds-slider
        id={@id}
        name={@name}
        value={@value}
        label-text={@label}
        {common(assigns)}
        {@carbon}
        {@rest}
      >
      </cds-slider>
    </div>
    """
  end

  def input(%{type: "date"} = assigns) do
    ~H"""
    <div style={field_style()}>
      <cds-date-picker date-format="Y-m-d" value={@value} {@carbon}>
        <cds-date-picker-input
          id={@id}
          name={@name}
          kind="single"
          label-text={@label}
          placeholder="yyyy-mm-dd"
          {common(assigns)}
          {@rest}
        >
        </cds-date-picker-input>
      </cds-date-picker>
    </div>
    """
  end

  def input(%{type: "time"} = assigns) do
    ~H"""
    <div style={field_style()}>
      <cds-time-picker
        id={@id}
        name={@name}
        value={Phoenix.HTML.Form.normalize_value("time", @value)}
        label-text={@label}
        {common(assigns)}
        {@carbon}
        {@rest}
      >
      </cds-time-picker>
    </div>
    """
  end

  def input(%{type: "file"} = assigns) do
    ~H"""
    <div style={field_style()}>
      <cds-file-uploader label-title={@label} label-description={@helper_text} {@carbon}>
        <cds-file-uploader-button
          id={@id}
          name={@name}
          accept={@rest[:accept]}
          multiple={@multiple}
          disabled={@rest[:disabled]}
        >
          {@prompt || "Add file"}
        </cds-file-uploader-button>
      </cds-file-uploader>
      <p :if={@errors != []} class={@class} style="color: var(--cds-text-error, #da1e28)">
        {Enum.join(@errors, " ")}
      </p>
    </div>
    """
  end

  # All other inputs text, email, password, number, search, etc.
  def input(assigns) do
    tag = text_tag(assigns.type)

    attrs =
      Map.merge(
        %{
          "id" => assigns.id,
          "name" => assigns.name,
          "type" => if(tag == "cds-text-input", do: assigns.type),
          "value" => Phoenix.HTML.Form.normalize_value(assigns.type, assigns[:value])
        },
        Map.merge(label_attr(tag, assigns.label), common(assigns))
      )
      |> Map.merge(assigns.carbon)
      |> Map.merge(assigns.rest)

    assigns = assign(assigns, tag: tag, attrs: attrs)

    ~H"""
    <div style={field_style()}>
      <.dynamic_tag tag_name={@tag} {@attrs}></.dynamic_tag>
    </div>
    """
  end

  defp field_style, do: @field_style

  defp select_attrs(assigns) do
    tag = assigns.tag

    %{
      "id" => assigns.id,
      "name" => assigns.name,
      "value" => Enum.join(assigns.selected, ","),
      "multiple" => tag == "cds-select" && assigns.multiple,
      "label" => if(tag != "cds-select", do: assigns.prompt),
      "placeholder" => if(tag == "cds-select", do: assigns.prompt)
    }
    |> Map.merge(label_attr(tag, assigns.label))
    |> Map.merge(common(assigns))
    |> Map.merge(assigns.carbon)
    |> Map.merge(assigns.rest)
  end

  defp text_tag("password"), do: "cds-password-input"
  defp text_tag("number"), do: "cds-number-input"
  defp text_tag("search"), do: "cds-search"
  defp text_tag(_), do: "cds-text-input"

  defp select_tag("select", true), do: "cds-multi-select"
  defp select_tag("select", _), do: "cds-select"
  defp select_tag("dropdown", _), do: "cds-dropdown"
  defp select_tag("combo-box", _), do: "cds-combo-box"
  defp select_tag("multi-select", _), do: "cds-multi-select"

  # The attribute that carries the visible label differs between controls.
  defp label_attr(tag, label) when tag in ["cds-select", "cds-search"],
    do: %{"label-text" => label}

  defp label_attr(tag, label) when tag in ["cds-dropdown", "cds-combo-box", "cds-multi-select"],
    do: %{"title-text" => label}

  defp label_attr(_tag, label), do: %{"label" => label}

  # Attributes shared by (nearly) all Carbon form controls.
  defp common(assigns) do
    %{
      "helper-text" => assigns.helper_text,
      "hide-label" => assigns.hide_label,
      "size" => assigns.size,
      "warn" => assigns.warn,
      "warn-text" => assigns.warn_text,
      "inline" => assigns.inline,
      "invalid" => assigns.errors != [],
      "invalid-text" => if(assigns.errors != [], do: Enum.join(assigns.errors, " ")),
      "class" => assigns.class
    }
  end

  defp selected_values(nil), do: []
  defp selected_values(values) when is_list(values), do: Enum.map(values, &to_string/1)
  defp selected_values(value), do: [to_string(value)]

  defp normalize_options(options) do
    Enum.map(options, fn
      {label, [_ | _] = nested} -> {:group, to_string(label), normalize_options(nested)}
      {label, value} -> {:item, to_string(label), to_string(value)}
      value -> {:item, to_string(value), to_string(value)}
    end)
  end

  attr :tag, :string, required: true
  attr :item, :any, required: true
  attr :selected, :list, required: true

  defp option_item(%{item: {:group, label, items}, tag: "cds-select"} = assigns) do
    assigns = assign(assigns, label: label, items: items)

    ~H"""
    <cds-select-item-group label={@label}>
      <.option_item :for={item <- @items} tag={@tag} item={item} selected={@selected} />
    </cds-select-item-group>
    """
  end

  defp option_item(%{item: {:group, _label, items}} = assigns) do
    assigns = assign(assigns, :items, items)

    ~H"""
    <.option_item :for={item <- @items} tag={@tag} item={item} selected={@selected} />
    """
  end

  defp option_item(%{item: {:item, label, value}, tag: "cds-select"} = assigns) do
    assigns = assign(assigns, label: label, value: value)

    ~H"""
    <cds-select-item label={@label} value={@value} selected={@value in @selected}></cds-select-item>
    """
  end

  defp option_item(%{item: {:item, label, value}} = assigns) do
    assigns =
      assign(assigns, label: label, value: value, item_tag: assigns.tag <> "-item")

    ~H"""
    <.dynamic_tag tag_name={@item_tag} {%{"value" => @value, "selected" => @value in @selected}}>
      {@label}
    </.dynamic_tag>
    """
  end

  ## Header

  @doc """
  Renders a header with title.
  """
  attr :carbon, :map, default: %{}, doc: "additional attributes for the `cds-heading` element"
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header style={[
      "padding-block-end: var(--cds-spacing-05, 1rem);",
      @actions != [] &&
        "display: flex; align-items: center; justify-content: space-between; gap: var(--cds-spacing-06, 1.5rem);"
    ]}>
      <div>
        <cds-heading {@carbon}>{render_slot(@inner_block)}</cds-heading>
        <p
          :if={@subtitle != []}
          style="color: var(--cds-text-secondary, #525252); font-size: 0.875rem;"
        >
          {render_slot(@subtitle)}
        </p>
      </div>
      <div :if={@actions != []} style="flex: none;">{render_slot(@actions)}</div>
    </header>
    """
  end

  ## Table

  @doc """
  Renders a Carbon data table.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username" sortable>{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  attr :size, :string, default: nil, values: [nil, "xs", "sm", "md", "lg", "xl"]
  attr :zebra, :boolean, default: true, doc: "use zebra striping"
  attr :selectable, :boolean, default: false, doc: "show row selection checkboxes"
  attr :expandable, :boolean, default: false
  attr :sortable, :boolean, default: false, doc: "make all columns sortable"
  attr :with_header, :boolean, default: false
  attr :use_static_width, :boolean, default: false
  attr :carbon, :map, default: %{}, doc: "additional attributes for the `cds-table` element"

  slot :col, required: true do
    attr :label, :string
    attr :sortable, :boolean
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <cds-table
      id={"#{@id}-table"}
      size={@size}
      use-zebra-styles={@zebra}
      is-selectable={@selectable}
      expandable={@expandable}
      is-sortable={@sortable}
      with-header={@with_header}
      use-static-width={@use_static_width}
      {@carbon}
    >
      <cds-table-head>
        <cds-table-header-row>
          <cds-table-header-cell :for={col <- @col} is-sortable={col[:sortable]}>
            {col[:label]}
          </cds-table-header-cell>
          <cds-table-header-cell :if={@action != []}>
            <span class="cds--visually-hidden">Actions</span>
          </cds-table-header-cell>
        </cds-table-header-row>
      </cds-table-head>
      <cds-table-body id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <cds-table-row :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <cds-table-cell
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            style={@row_click && "cursor: pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </cds-table-cell>
          <cds-table-cell :if={@action != []}>
            <div style="display: flex; gap: var(--cds-spacing-05, 1rem);">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </cds-table-cell>
        </cds-table-row>
      </cds-table-body>
    </cds-table>
    """
  end

  ## List

  @doc """
  Renders a data list as a Carbon structured list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  attr :condensed, :boolean, default: false, doc: "use less vertical space"
  attr :flush, :boolean, default: false, doc: "remove horizontal padding"

  attr :carbon, :map,
    default: %{},
    doc: "additional attributes for the `cds-structured-list` element"

  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <cds-structured-list condensed={@condensed} flush={@flush} {@carbon}>
      <cds-structured-list-body>
        <cds-structured-list-row :for={item <- @item}>
          <cds-structured-list-cell no-wrap>
            <strong>{item.title}</strong>
          </cds-structured-list-cell>
          <cds-structured-list-cell>{render_slot(item)}</cds-structured-list-cell>
        </cds-structured-list-row>
      </cds-structured-list-body>
    </cds-structured-list>
    """
  end

  ## Icon

  @doc """
  Renders a [Carbon icon](https://carbondesignsystem.com/elements/icons/library/).

  Pass the icon name as shown in the library, e.g. `add`, `warning--filled`
  or `chevron--down`. Icons use `currentColor` and scale to any size.

  ## Examples

      <.icon name="add" />
      <.icon name="renew" size={24} class="spin" />
      <.icon name="close" label="Close dialog" />
  """
  attr :name, :string, required: true, doc: "the Carbon icon name"
  attr :size, :any, default: 16, doc: "width and height in pixels"
  attr :label, :string, default: nil, doc: "accessible label; the icon is decorative without it"
  attr :class, :any, default: nil
  attr :rest, :global

  def icon(assigns) do
    assigns =
      assign(assigns, :markup, Phoenix.HTML.raw(CarbonPhoenix.Icons.get(assigns.name)))

    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 32 32"
      width={@size}
      height={@size}
      fill="currentColor"
      class={@class}
      role={@label && "img"}
      aria-label={@label}
      aria-hidden={is_nil(@label) && "true"}
      focusable="false"
      {@rest}
    >{@markup}</svg>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector), do: JS.show(js, to: selector)

  def hide(js \\ %JS{}, selector), do: JS.hide(js, to: selector, time: 200)

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # You can make use of gettext to translate error messages by
    # uncommenting and adjusting the following code:

    # if count = opts[:count] do
    #   Gettext.dngettext(MyAppWeb.Gettext, "errors", msg, msg, count, opts)
    # else
    #   Gettext.dgettext(MyAppWeb.Gettext, "errors", msg, opts)
    # end

    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
