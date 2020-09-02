defmodule NookBook.Data.Setup do
  def setup do
    :mnesia.start()
    create_schema()
  end

  def create_schema do
    if schema_exists_anywhere?() do
      {:ok, :already_created}
    else
      stop_mnesia_everywhere()
      :mnesia.stop()
      :mnesia.create_schema(nodes())
      :mnesia.start()
      start_mnesia_everywhere()
    end
  end

  def schema_exists_anywhere? do
    {answers, _} = :rpc.multicall(nodes(), NookBook.Data.Setup, :schema_exists?, [])
    Enum.any?(answers, fn x -> x end)
  end

  def stop_mnesia_everywhere do
    [:visible]
    |> Node.list()
    |> Enum.each(fn node -> Node.spawn_link(node, :mnesia.stop/0) end)
  end

  def start_mnesia_everywhere do
    [:visible]
    |> Node.list()
    |> Enum.each(fn node -> Node.spawn_link(node, :mnesia.start/0) end)
  end

  def nodes, do: [node() | Node.list([:visible])]

  def schema_exists?, do: :mnesia.table_info(:schema, :disc_copies) != []
end
