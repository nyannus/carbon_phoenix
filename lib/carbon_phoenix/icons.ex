defmodule CarbonPhoenix.Icons do
  @moduledoc """
  Compile-time lookup of the [Carbon icons](https://carbondesignsystem.com/elements/icons/library/).

  The 32px SVGs from the `@carbon/icons` npm package (install it in your
  app: `npm install --prefix assets @carbon/icons`) are read at compile time and stored as a map of
  icon name to inner SVG markup. They scale to any size, so only the 32px
  variant is embedded.

  If the npm package is not installed when compiling, the lookup is empty and
  `CarbonPhoenix.Components.icon/1` renders an empty `<svg>`.
  """

  @icons_subdir "node_modules/@carbon/icons/svg/32"

  # Where to look for the `@carbon/icons` npm package, first hit wins:
  #   1. $CARBON_ICONS_PATH (the `svg/32` directory)
  #   2. this package's own node_modules (library development)
  #   3. the host app's assets/node_modules (this file lives in deps/carbon_phoenix/lib/carbon_phoenix)
  #   4. ./assets/node_modules relative to the working directory
  @candidates [
                System.get_env("CARBON_ICONS_PATH"),
                Path.expand("../../" <> @icons_subdir, __DIR__),
                Path.expand("../../../../assets/" <> @icons_subdir, __DIR__),
                Path.expand("assets/" <> @icons_subdir)
              ]
              |> Enum.reject(&is_nil/1)

  @icons_dir Enum.find(@candidates, &File.dir?/1)

  if @icons_dir == nil do
    IO.warn(
      "carbon_phoenix: @carbon/icons not found, <.icon> will render empty SVGs. " <>
        "Run `npm install --prefix assets @carbon/icons` and recompile with " <>
        "`mix deps.compile carbon_phoenix --force`."
    )
  end

  @icons (for path <- Path.wildcard(Path.join(@icons_dir || "", "*.svg")), into: %{} do
            svg = File.read!(path)
            [_, inner] = Regex.run(~r/<svg[^>]*>(.*)<\/svg>/s, svg)
            {Path.basename(path, ".svg"), inner}
          end)

  @doc "Returns the inner SVG markup for the icon `name`, or `nil`."
  @spec get(String.t()) :: String.t() | nil
  def get(name), do: Map.get(@icons, name)

  @doc "Lists all available icon names."
  @spec names() :: [String.t()]
  def names, do: @icons |> Map.keys() |> Enum.sort()
end
