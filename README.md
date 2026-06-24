# Code for America Engineering Command Line Tool

> [!CAUTION]
> This is a work in progress. You are welcome to try it out, and contribute,
> but it should not be considered stable or production-ready.

`cfa-eng` is a CLI tool for Code for America engineering teams. It manages AWS
bastion host connections, named profiles, and OpenTofu infrastructure operations.

## Requirements

- Ruby 3.3+
- [AWS CLI](https://aws.amazon.com/cli/) with the
  [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
- [Doppler CLI](https://docs.doppler.com/docs/install-cli) (for `tofu` commands)
- [OpenTofu](https://opentofu.org/docs/intro/install/) (for `tofu` commands)

## Installation

```bash
gem install cfa-eng-cli
```

Or add it to your `Gemfile`:

```ruby
gem 'cfa-eng-cli'
```

## Configuration

`cfa-eng` uses **profiles** to store named sets of connection settings. Most
commands require a profile, specified with `--profile` or the `CFA_PROFILE`
environment variable.

```bash
export CFA_PROFILE=my-app
```

Profile files are stored as YAML in `~/.codeforamerica/profiles/`.

<!-- cspell:ignore codeforamerica -->

## Commands

### `profile` — Manage profiles

#### `profile create`

Creates a new profile. All fields can be supplied as options; any omitted fields
are prompted for interactively.

```bash
cfa-eng profile create
cfa-eng profile create --name my-app --project snap --environment staging \
  --aws-profile shared-services-dev --region us-east-1
```

| Option | Description |
|---|---|
| `--name` | Profile name |
| `--project` | Project name |
| `--environment` | Deployment environment (e.g. `staging`, `production`) |
| `--aws-profile` | AWS CLI profile to use for credentials |
| `--region` | Primary AWS region (default: `us-east-1`) |
| `--doppler-project` | Doppler project for secrets (default: `shared-services`) |
| `--doppler-environment` | Doppler environment prefix used for config names, e.g. `infra` produces configs like `infra_dev`, `infra_prod`, `infra_<env>` (default: `infra`) |

#### `profile list`

Lists all saved profiles.

```bash
cfa-eng profile list
```

#### `profile delete PROFILE`

Deletes a profile. Prompts for confirmation unless `--yes` is given.

```bash
cfa-eng profile delete my-app
cfa-eng profile delete my-app --yes
```

#### `profile rename PROFILE NAME`

Renames a profile. Prompts for confirmation unless `--yes` is given.

```bash
cfa-eng profile rename my-app my-renamed-app
cfa-eng profile rename my-app my-renamed-app --yes
```

---

### `bastion` — Connect to bastion hosts

The `bastion` commands connect to AWS bastion hosts via SSM Session Manager port
forwarding. A profile is required for all bastion commands.

All `bastion` commands accept:

| Option | Description |
|---|---|
| `--profile NAME` | Profile to use (default: `$CFA_PROFILE`) |

#### `bastion create-tunnel`

Adds a tunnel configuration to a profile. Prompts interactively for tunnel
settings.

```bash
cfa-eng bastion create-tunnel --profile my-app
```

#### `bastion delete-tunnel NAME`

Removes a named tunnel configuration from a profile.

```bash
cfa-eng bastion delete-tunnel my-db --profile my-app
```

#### `bastion tunnel`

Opens an SSH tunnel through the bastion to a remote host using a saved tunnel
configuration.

```bash
cfa-eng bastion tunnel --name my-db --profile my-app
```

| Option | Description |
|---|---|
| `--name` | Name of the tunnel configuration to use |

---

### `tofu` — Run OpenTofu operations

The `tofu` commands wrap common OpenTofu operations. They automatically fetch
secrets from Doppler, select the appropriate AWS profile for the environment,
and run `tofu init` before each operation.

A profile is required for all `tofu` commands and supplies the environment,
AWS credentials, project name, and Doppler project.

All `tofu` commands accept:

| Option | Description |
|---|---|
| `--profile NAME` | Profile to use (default: `$CFA_PROFILE`) |

These commands must be run from the root of an OpenTofu repository (a directory
containing `tofu/configs/`).

#### `tofu plan CONFIG`

Runs `tofu plan -concise` for the given configuration layer.

```bash
cfa-eng tofu plan foundation --profile my-app
cfa-eng tofu plan application --profile my-app --args="-out tfplan"
```

| Option | Description |
|---|---|
| `--args STRING` | Extra arguments forwarded to `tofu plan` |

#### `tofu apply CONFIG`

Runs `tofu apply` for the given configuration layer.

```bash
cfa-eng tofu apply foundation --profile my-app
cfa-eng tofu apply application --profile my-app --args="-auto-approve"
```

| Option | Description |
|---|---|
| `--args STRING` | Extra arguments forwarded to `tofu apply` |

#### `tofu destroy CONFIG`

Runs `tofu destroy` for the given configuration layer.

```bash
cfa-eng tofu destroy application --profile my-app
```

| Option | Description |
|---|---|
| `--args STRING` | Extra arguments forwarded to `tofu destroy` |

#### `tofu output CONFIG`

Shows the outputs for the given configuration layer.

```bash
cfa-eng tofu output foundation --profile my-app
cfa-eng tofu output foundation --profile my-app --args="-json"
```

| Option | Description |
|---|---|
| `--args STRING` | Extra arguments forwarded to `tofu output` |

#### `tofu force-unlock CONFIG LOCK_ID`

Force-unlocks a stuck state lock for the given configuration layer. Prompts for
confirmation before proceeding. Does not fetch Doppler secrets.

```bash
cfa-eng tofu force-unlock foundation abc-1234-5678 --profile my-app
```

> [!WARNING]
> Only use this if you are certain the lock is stale. Unlocking while another
> operation is in progress will corrupt state.

#### `tofu bootstrap`

Bootstraps the remote S3 state backend for a new environment. If the state
bucket does not yet exist, it applies the `foundation` configuration with a
local backend first and then migrates state to S3.

```bash
cfa-eng tofu bootstrap --profile my-app
```

> [!NOTE]
> `tofu bootstrap` always operates on `tofu/configs/foundation`.

### AWS profile selection

For `tofu` commands, the AWS profile is taken from the saved profile's
`aws_profile` field. If no `aws_profile` is stored in the profile, the CLI
selects a default based on the environment:

| Environment | Default AWS profile |
|---|---|
| `production` | `shared-services-prod` |
| All others | `shared-services-dev` |

A red warning is printed before any operation targeting `production`.
