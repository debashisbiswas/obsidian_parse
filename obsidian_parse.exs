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

defmodule GraphNode do
  defstruct [:name]
  @type t :: %__MODULE__{name: String.t()}
end

defmodule GraphEdge do
  defstruct [:from, :to]
  @type t :: %__MODULE__{from: String.t(), to: String.t()}
end

defmodule Graph do
  defstruct nodes: [], edges: []
  @type t :: %__MODULE__{nodes: list(GraphNode.t()), edges: list(GraphEdge.t())}

  def add_node(graph, name) do
    new_node = %GraphNode{name: name}
    %Graph{nodes: [new_node | graph.nodes], edges: graph.edges}
  end

  def add_edge(graph, from, to) do
    new_edge = %GraphEdge{from: from, to: to}
    %Graph{nodes: graph.nodes, edges: [new_edge | graph.edges]}
  end
end

defmodule Main do
  def main() do
    if Enum.count(System.argv()) != 1 do
      IO.puts("Pass one argument")
      System.halt(1)
    end

    path = System.argv() |> Enum.at(0)

    if not File.dir?(path) do
      IO.puts("#{path} is not a directory")
      System.halt(1)
    end

    ########################################
    # exploring the graph abstraction
    ########################################

    graph = %Graph{}

    graph = graph |> Graph.add_node("new node!")
    graph = graph |> Graph.add_node("another one")
    graph = graph |> Graph.add_edge("new node!", "another one")

    IO.inspect(graph)

    ########################################
    # parsing files
    ########################################

    Path.wildcard("#{path}/**/*.md")
    |> Enum.map(&ObsidianParse.read_file/1)
    |> Enum.map(&ObsidianParse.parse_content/1)
    |> Enum.map(&ObsidianParse.get_links/1)
    |> Enum.reject(&is_nil/1)
    |> IO.inspect()
  end
end

Main.main()
