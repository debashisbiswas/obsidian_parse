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

  def add_node(graph, name) do
    new_nodes = graph.nodes |> MapSet.put(%GraphNode{name: name})
    %Graph{nodes: new_nodes, edges: graph.edges}
  end

  def add_nodes(graph, names_list) do
    new_nodes =
      names_list
      |> Enum.map(&%GraphNode{name: &1})
      |> MapSet.new()
      |> MapSet.union(graph.nodes)

    %Graph{nodes: new_nodes, edges: graph.edges}
  end

  def add_edge(graph, from, to) do
    new_edges = [%GraphEdge{from: from, to: to} | graph.edges]
    %Graph{nodes: graph.nodes, edges: new_edges}
  end

  def add_edges(graph, from, to_list) do
    new_edges = Enum.map(to_list, &%GraphEdge{from: from, to: &1})
    %Graph{nodes: graph.nodes, edges: new_edges ++ graph.edges}
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

  def extract_links(document) do
    document[MDEx.WikiLink]
    |> case do
      nil -> []
      links -> Enum.map(links, fn link -> link.url end)
    end
  end

  defp visit_file(path, graph) do
    name = Path.basename(path, ".md")
    outgoing_links = path |> read_file |> parse_content |> extract_links

    graph
    |> Graph.add_nodes([name | outgoing_links])
    |> Graph.add_edges(name, outgoing_links)
  end

  def build_graph(directory_path) do
    paths = Path.wildcard("#{directory_path}/**/*.md")

    Enum.reduce(paths, %Graph{}, &visit_file/2)
  end
end

defmodule Main do
  def main() do
    if System.argv() |> Enum.count() != 1 do
      IO.puts("Pass one argument")
      System.halt(1)
    end

    path = System.argv() |> Enum.at(0)

    if not File.dir?(path) do
      IO.puts("#{path} is not a directory")
      System.halt(1)
    end

    graph = ObsidianParse.build_graph(path)

    graph |> IO.inspect()
  end
end

Main.main()
