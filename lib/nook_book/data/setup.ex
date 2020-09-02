defmodule NookBook.Data.Setup do
  require Logger

  @tables [
    NookBook.Data.GenericCache
  ]

  def setup(:primary) do
    Logger.info("Setting up mnesia for primary node")
    :mnesia.start()
    create_schema()
    create_tables()
  end

  def setup(:member) do
    :nook_book
    |> Application.get_env(:primary_node)
    |> Node.connect()

    Logger.info("Setting up mnesia for member node, cluster peers:")
    Logger.info(inspect(nodes()))

    [existing_node | _] = Node.list([:visible])
    node = Node.self()
    :mnesia.start()
    {:ok, _} = :rpc.call(existing_node, :mnesia, :change_config, [:extra_db_nodes, [node]])

    :mnesia.change_table_copy_type(:schema, node, :disc_copies)
    :mnesia.add_table_copy(:schema, node, :disc_copies)
    sync_remote_tables_to_local_disk()
  end

  def sync_remote_tables_to_local_disk do
    node = Node.self()

    :mnesia.system_info(:tables)
    |> Enum.each(fn table ->
      if node in :mnesia.table_info(table, :disc_copies) do
        :ok
      else
        Logger.info("Syncing #{table}")
        :mnesia.add_table_copy(:schema, node, :disc_copies)
      end
    end)
  end

  def create_tables do
    @tables
    |> Enum.each(&create_table/1)
  end

  def create_table(module) do
    if table_exists?(module.table_name()) do
      {:ok, :already_created}
    else
      :mnesia.create_table(
        module.table_name(),
        attributes: module.table_fields(),
        type: module.table_type(),
        index: module.table_indexes(),
        disc_copies: nodes()
      )
    end
  end

  def table_exists?(table_name) do
    :tables
    |> :mnesia.system_info()
    |> Enum.member?(table_name)
  end

  def wait_for_tables do
    table_names()
    |> :mnesia.wait_for_tables(10_000)
  end

  def table_names do
    @tables
    |> Enum.map(&apply(&1, :table_name, []))
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
    nodes()
    |> :rpc.multicall(__MODULE__, :schema_exists?, [])
    |> elem(0)
    |> Enum.any?()
  end

  def stop_mnesia_everywhere do
    [:visible]
    |> Node.list()
    |> Enum.each(&Node.spawn_link(&1, :mnesia.stop() / 0))
  end

  def start_mnesia_everywhere do
    [:visible]
    |> Node.list()
    |> Enum.each(&Node.spawn_link(&1, :mnesia.start() / 0))
  end

  def nodes, do: [node() | Node.list([:visible])]

  def schema_exists?, do: :mnesia.table_info(:schema, :disc_copies) != []
end
