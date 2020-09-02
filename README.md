# NookBook

Repo: https://github.com/versus-systems/nook_book

API: https://acnhapi.com

You need to develop your own strategy, mnesia gives you the basic.

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Install Node.js dependencies with `npm install` inside the `assets` directory

```sh
PORT=4000 CLUSTER_ROLE=primary iex --name n1@127.0.0.1 --cookie secret -S mix phx.server
```

```sh
PORT=4001 CLUSTER_ROLE=member iex --name n2@127.0.0.1 --cookie secret -S mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
Now you can visit [`localhost:4001`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
