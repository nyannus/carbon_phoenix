defmodule CarbonPhoenix.ComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import CarbonPhoenix.Components
  import CarbonPhoenix.WebComponents

  defp html(rendered), do: rendered |> rendered_to_string() |> LazyHTML.from_fragment()
  defp has?(doc, selector), do: LazyHTML.query(doc, selector) |> Enum.count() > 0

  test "button renders a cds-button with kind and navigation bindings" do
    assigns = %{}

    doc =
      html(~H"""
      <.button navigate="/home" kind="tertiary" size="sm">Home</.button>
      """)

    assert has?(
             doc,
             ~s(cds-button[kind="tertiary"][size="sm"][href="/home"][data-phx-link="redirect"])
           )
  end

  test "button defaults to primary" do
    assigns = %{}
    doc = html(~H"<.button>Go</.button>")
    assert has?(doc, ~s(cds-button[kind="primary"]))
  end

  test "icon renders inline svg from the Carbon icon set" do
    assigns = %{}
    doc = html(~H|<.icon name="add" size={24} />|)
    assert has?(doc, ~s(svg[width="24"] path))
  end

  test "input renders matching Carbon elements and errors" do
    assigns = %{}

    doc =
      html(~H"""
      <.input name="a" id="a" type="email" label="Mail" errors={["bad"]} />
      <.input name="b" id="b" type="password" label="Pw" />
      <.input name="c" id="c" type="select" label="Sel" options={[A: "a", B: "b"]} value="b" />
      <.input name="d" id="d" type="checkbox" label="Chk" value={true} />
      <.input name="e" id="e" type="radio-group" label="Rad" options={["x", "y"]} />
      <.input name="f" id="f" type="dropdown" label="Dd" options={["x", "y"]} value="y" />
      """)

    assert has?(
             doc,
             ~s(cds-text-input#a[type="email"][invalid][invalid-text="bad"][label="Mail"])
           )

    assert has?(doc, "cds-password-input#b")
    assert has?(doc, ~s(cds-select#c cds-select-item[value="b"][selected]))
    assert has?(doc, "cds-checkbox#d[checked]")
    assert has?(doc, "cds-radio-button-group#e cds-radio-button")
    assert has?(doc, "cds-dropdown#f cds-dropdown-item[selected]")
  end

  test "table renders rows and cells" do
    assigns = %{rows: [%{id: 1, name: "a"}]}

    doc =
      html(~H"""
      <.table id="t" rows={@rows}>
        <:col :let={r} label="Name">{r.name}</:col>
      </.table>
      """)

    assert has?(doc, "cds-table cds-table-body#t cds-table-row cds-table-cell")
  end

  test "generated components expose carbon attributes and event bridge" do
    assigns = %{}

    doc =
      html(~H"""
      <.cds_modal id="m" open size="sm" on={%{"cds-modal-closed" => "closed"}}>x</.cds_modal>
      <.cds_tag type="red">t</.cds_tag>
      """)

    assert has?(doc, ~s(cds-modal#m[open][size="sm"][phx-hook="CarbonEvents"][data-carbon-on]))
    assert has?(doc, ~s(cds-tag[type="red"]))
  end
end
