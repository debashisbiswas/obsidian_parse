#!/usr/bin/env elixir

Mix.install([
  {:mdex, "~> 0.3.3"}
])

defmodule GraphNode do
  defstruct [:name]
  @type t :: %__MODULE__{name: String.t()}
end

defmodule GraphEdge do
  defstruct [:from, :to]
  @type t :: %__MODULE__{from: String.t(), to: String.t()}
end

defmodule Graph do
  defstruct nodes: MapSet.new(), edges: []
  @type t :: %__MODULE__{nodes: MapSet.t(GraphNode.t()), edges: list(GraphEdge.t())}

  defp add_node(graph, name) do
    new_nodes = graph.nodes |> MapSet.put(%GraphNode{name: name})
    %Graph{nodes: new_nodes, edges: graph.edges}
  end

  def add_edge(graph, from, to) do
    graph = graph |> add_node(from) |> add_node(to)

    new_edges = [%GraphEdge{from: from, to: to} | graph.edges]
    %Graph{nodes: graph.nodes, edges: new_edges}
  end
end

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
    |> case do
      nil -> nil
      links -> Enum.map(links, fn link -> link.url end)
    end
  end

  def build_graph(paths) do
    Enum.reduce(paths, %Graph{}, fn path, graph ->
      name = Path.basename(path, ".md")
      outgoing_links = path |> read_file |> parse_content |> get_links

      case outgoing_links do
        nil ->
          graph

        outgoing_links ->
          Enum.reduce(outgoing_links, graph, fn link, acc_graph ->
            Graph.add_edge(acc_graph, name, link)
          end)
      end
    end)
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

    graph =
      Path.wildcard("#{path}/**/*.md")
      |> ObsidianParse.build_graph()

    IO.inspect(graph)
  end
end

Main.main()
