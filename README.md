# WeDle

## Real-time distributed multiplayer Wordle-like game

WIP running at [we-dle.fly.dev](https://we-dle.fly.dev)

## What is `we-dle`?

The goal for `we-dle` is to build a massively concurrent and distributed real-time multiplayer version of
a Wordle-like game. Players can play head-to-head with a friend anywhere in the world. The first player
to correctly guess the challenge word wins. Players are updated on their opponent's progress in real-time
with a live Wordle grid.

Three basic game modes are planned:

  * Classic - Both players are challenged to guess today's official Wordle word. This game mode can only
  be played once per day per browser session.

  * Any Wordle - Each player selects the challenge word for their opponent to guess. Words must be
  selected from the official complete Wordle word list.

  * Freestyle - Each player selects the challenge word for their opponent to guess. Words can be any length
  from 3 to 10 letters and can contain any Unicode character.

All player information is non-sensitive and stored in browser cookies. Player information includes statistics,
accessibility preferences, and a random unique ID used only to join games.

## Technology stack

`we-dle` is being built with the PETAL stack.

  * P - [Phoenix](https://www.phoenixframework.org/)
  * E - [Elixir](https://elixir-lang.org)
  * T - [Tailwind CSS](https://tailwindcss.com/)
  * A - [Alpine.js](https://alpinejs.dev/)
  * L - [LiveView](https://hexdocs.pm/phoenix_live_view)

The following critical technologies and libraries are also leveraged:

  * [Erlang/OTP](https://www.erlang.org/) and the BEAM
  * [PostgreSQL](https://www.postgresql.org/)
  * [libcluster](https://github.com/bitwalker/libcluster)
  * [horde](https://github.com/derekkraan/horde)
  * [Fly.io](https://fly.io)

`we-dle` takes advantage of the concurrency, scalabilty, and fault tolerance of the BEAM, and the
productivity and maintainability of the PETAL stack. Libcluster is used for easy clustering of distributed
Elixir nodes, and Horde is used for its delta-CRDT backed global process registration, allowing game server
processes to be discoverable anywhere in the cluster. Deployment is on Fly.io which provides direct control 
over server distribution in over a dozen regions globally, and secure WireGuard networking between the
cluster, which makes it a perfect fit for distributed Elixir/Phoenix/LiveView apps.

Nodes are gracefully shutdown on down-scaling and during deployments, giving game server processes time
to save their current state in the Postgres database. State is recovered when the process restarts on the
same or a different node. As cluster topology changes the Horde distributed registry syncs among all nodes,
making every game process globally discoverable in the cluster, allowing players to connect no matter which
server they are load balanced to.

## Getting started

To run this project locally:

  * Fork and clone this repo
  * `cd we-dle`
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Run the tests `mix test`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Contributing

To contribute:

  * Create a feature branch
  * Make your changes
  * Write tests
  * Write documentation and typespecs for "core" modules and functions
  * Run tests, formatter, and Credo code linter with `mix we_dle`
  * If all checks pass, push to your repository and create a pull request with a summary
  of what your changes are and why you've made them
  * Please keep PRs small and limited in scope

If you can run a [LiveBook](https://livebook.dev/) server locally you can open the open the project
notebooks in the `./notebooks/` directory. Connect your server's runtime to the project by using the
"Mix standalone" runtime setting.

## Sponsorship

This is a free, open-source project made by one creator, hopefully with help from volunteer contributors.
Running a multi-player version of Wordle requires paying for servers positioned around the world, which can
get expensive if a lot of people use it. The cost of running the servers is directly related to how many
people enjoy playing `we-dle` on a daily basis. If you enjoy playing `we-dle` or want to see it succeed,
your support helps fund those costs.

[https://www.patreon.com/we_dle](https://www.patreon.com/we_dle)

## [License](LICENSE)

Copyright 2022 Matthew Simon Borg

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.