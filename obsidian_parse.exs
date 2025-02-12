#!/usr/bin/env elixir

Mix.install([
  {:mdex, "~> 0.3.3"}
])

defmodule ObsidianParse do
  def read_file(path) do
    case File.read(path) do
      {:ok, content} -> content
      {:error, :enoent} -> "File does not exist: #{path}"
      {:error, reason} -> "Could not open file: #{reason}"
    end
  end

  def parse_content(content) do
    content
    |> MDEx.parse_document!(
      extension: [
        strikethrough: true,
        tagfilter: true,
        table: true,
        autolink: true,
        tasklist: true,
        footnotes: true,
        shortcodes: true,
        front_matter_delimiter: "---",
        wikilinks_title_after_pipe: true
      ]
    )
  end

  def get_links(document) do
    document[MDEx.WikiLink]
  end

  def main(content) do
    content
    |> parse_content
    |> get_links
  end
end

if Enum.count(System.argv()) != 1 do
  IO.puts("Pass one argument")
  System.halt(1)
end

path = System.argv() |> Enum.at(0)

if not File.dir?(path) do
  IO.puts("#{path} is not a directory")
  System.halt(1)
end

Path.wildcard("#{path}/**/*.md")
|> Enum.map(&ObsidianParse.read_file/1)
|> Enum.map(&ObsidianParse.parse_content/1)
|> Enum.map(&ObsidianParse.get_links/1)
|> Enum.count()
|> IO.puts()
