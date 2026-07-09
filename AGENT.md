# AGENT.md

This file provides guidance to coding agents when working with code in this
repository.

## Skills

This repository includes bundled skills for coding agents to use. These skills
can be found in the `.agents/skills` directory.

Some skills will be manually invoked based on the task at hand, others may need
to be invoked manually using `/<skill name>`.

| Skill        | Description                                                                                                                  |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| `/tech-spec` | Create a technical specification for a project, feature, or other task. Use when asked to develop a technical specification. |

## Commands

```bash
bundle exec rake              # lint + tests (default)
bundle exec rake rubocop      # lint only
bundle exec rake spec         # all tests
bundle exec rspec spec/unit/cfa_eng_cli/bastion_spec.rb  # single test file
```

## Architecture

This is a Ruby CLI gem for Code for America engineering teams, built on [Thor].
It manages AWS bastion host connections and named profiles.

### Entry point

- `bin/cfa-eng`: Defines the top-level Thor class and registers two subcommand
  groups.

### Two subcommand groups

- `bastion`: Manages tunnel configurations and opens SSH tunnels via AWS Session
  Manager port forwarding
- `profile`: Manages named connection profiles stored as YAML in
  `~/.codeforamerica/profiles/`

### Command layer

- `lib/cfa_eng_cli/commands/`: Each group is a Thor subcommand class inheriting
  from `Commands::Command` (`base.rb`); commands delegate to business logic
  classes rather than containing logic themselves.

### Business logic

- `Bastion`: Discovers running EC2 bastion instances by project/environment
  tags, constructs `SessionTarget`, and opens port-forwarding tunnels
- `SessionManager`: Wraps the AWS SSM `StartSession` API and shells out to the
  `session-manager-plugin` binary to maintain the connection

[thor]: https://github.com/rails/thor
