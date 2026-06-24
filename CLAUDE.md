# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bundle exec rake              # lint + tests (default)
bundle exec rake rubocop      # lint only
bundle exec rake spec         # all tests
bundle exec rspec spec/unit/cfa_eng_cli/bastion_spec.rb  # single test file
```

## Architecture

This is a Ruby CLI gem for Code for America engineering teams, built on [Thor](https://github.com/rails/thor). It manages AWS bastion host connections and named profiles.

**Entry point:** `bin/cfa-eng` — defines the top-level Thor class and registers two subcommand groups.

**Two subcommand groups:**
- `bastion` — creates/deletes tunnel configs and opens SSH tunnels via AWS Session Manager port forwarding
- `profile` — CRUD for named connection profiles stored as YAML in `~/.codeforamerica/profiles/`

**Command layer** (`lib/cfa_eng_cli/commands/`): Each group is a Thor subcommand class inheriting from `Commands::Command` (base.rb). Commands delegate to business logic classes rather than containing logic themselves.

**Business logic** (`lib/cfa_eng_cli/`):
- `Bastion` — discovers running EC2 bastion instances by project/environment tags, constructs `SessionTarget`, and opens port-forwarding tunnels
- `SessionManager` — wraps the AWS SSM `StartSession` API and shells out to the `session-manager-plugin` binary to maintain the connection
- `SessionTarget` — simple data object holding instance ID, region, and AWS profile name

**Config system** (`lib/cfa_eng_cli/config/`): Uses the [ConfigSL](https://github.com/codeforamerica/configsl) gem for declarative schema definitions. `Config::Base` handles YAML serialization. `Config::Profile` and `Config::RemoteTunnel` define the data shapes. Profile YAML files live at `~/.codeforamerica/profiles/<name>.yaml`.
