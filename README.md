# MyRelationshipManager

An interactive command-line tool for tracking people, companies, events, and how they connect. Data is stored in PostgreSQL by default when built with `-fpostgres`, or in SQLite when built without PostgreSQL support or when `--sqlite` is passed.

Built in Haskell as a proof of concept for a real world program, with both user and DB I/O.

## Data model

- **Modelled Entities:** people, companies, events, encounters (person at an event), employment links, sponsorship links
- **CRUD from the REPL:** `add`, `list`, and `delete` for each entity type
- **Interactive completion:** omit arguments and the program asks for them; pick existing records by id or type `new` to create one on the spot
- **Referential integrity:** foreign keys enforced; deletes are blocked when dependent rows still exist
- **Persistent storage:** PostgreSQL (default when built with `-fpostgres`) or a local SQLite file (`relationships.db`)

```
people ──┬── encounters ── events
         │                    │
         └── employment       └── sponsorship
                    │                    │
                companies ───────────────┘
```

| Table | Purpose |
|-------|---------|
| `people` | Name and notes |
| `companies` | Name and notes |
| `events` | Location, start/end (free-text), notes |
| `encounters` | A person at an event, with notes |
| `employment` | Many-to-many person ↔ company |
| `sponsorship` | Many-to-many event ↔ company |

`PRAGMA foreign_keys = ON` is set on every connection.

### Command format

```
<action> <object> [arguments]
```

| Action | Objects |
|--------|---------|
| `add` | `person`, `company`, `event`, `encounter`, `employment`, `sponsorship` |
| `list` | same |
| `delete` | same (see notes below for link types) |
| `quit` | *(no object)* |

Actions and object names are case-insensitive. Text arguments that contain spaces must be quoted.

#### Examples

```
add person "Jane Doe"
add company "Acme Corp"
list person
delete encounter 3
delete employment 1 2
quit
```

#### Partial commands

If you only type the verb and object, prompts fill in the rest:

```
add person
Enter name: Jane Doe
Enter notes: met at conference
Add employers now? (y/n)
```

For relationships (`encounter`, `employment`, `sponsorship`), the program lists existing records and accepts a numeric id or `new`:

```
add encounter
Enter person id, or 'new' to create one:
1
Enter event id, or 'new' to create one:
new
Enter location: Convention Center
...
```

#### Delete behavior

| Target | Syntax | Notes |
|--------|--------|-------|
| Person, company, event, encounter | `delete <object> <id>` | Person/event deletes fail while encounters still reference them |
| Employment | `delete employment <person_id> <company_id>` | Removes one link, not the person or company |
| Sponsorship | `delete sponsorship <event_id> <company_id>` | Removes one link, not the event or company |

Invalid input prints a short error and redisplays the available actions and objects.

## Technical details

### Requirements

- [GHC](https://www.haskell.org/ghc/) 9.6+ (GHC2021)
- [Cabal](https://www.haskell.org/cabal/) 3.x

All Haskell library dependencies are resolved by Cabal from Hackage. What you need beyond that depends on which database backend you build for (see below).


#### SQLite only (`-f-postgres`)

Use this when you only need the local file database, and don't want to/can't use the Postgres dependencies.

**System dependencies:** none beyond GHC/Cabal (SQLite is bundled with `sqlite-simple`).

**Haskell dependencies:** `base`, `sqlite-simple`, `text`, `unordered-containers`.

```bash
cabal build -f-postgres
cabal run myfirstsql -f-postgres
```

On first launch the program creates `relationships.db` in the current working directory and applies the schema. PostgreSQL flags are not available in this build.

#### With PostgreSQL (`-fpostgres`, default)

PostgreSQL queries use [Rel8](https://rel8.readthedocs.io/en/latest/cookbook.html) on top of Hasql. Table DDL is applied automatically on first connect.

**System dependencies:** the PostgreSQL **client** library (`libpq`), version **14.12 or newer**. Hasql links against `libpq` at compile time; you do not need a running server to build, but the development headers/libraries must be installed (e.g. `libpq-dev` on Debian/Ubuntu, PostgreSQL client tools on Windows).

**Extra Haskell dependencies** (pulled in only with `-fpostgres`): `hasql`, `rel8`, `bytestring`, `semialign`, `semigroupoids`.

```bash
cabal build                                   # same as cabal build -fpostgres
cabal run myfirstsql                          # PostgreSQL default (reads .env)
cabal run myfirstsql -- --postgres=host:port  # override host and port for PostgreSQL 
cabal run myfirstsql -- --sqlite              # use sqllite anyway
```

(reminder: `--` separates Cabal's own flags (e.g. `-fpostgres`) from arguments passed to the executable.)

##### Connecting to PostgreSQL

Configure connection settings via environment variables or a `.env` file in the project root (loaded on startup).

**1. Create the database** (once). The app creates tables on connect but not the database itself:

```bash
# example — adjust host, port, and psql path for your install
psql -U postgres -p 5433 -d postgres -f scripts/create-pg-database.sql
```

**2. Configure credentials.** On startup the program loads a `.env` file from the project root (if present) into the environment, then reads connection settings. Example `.env`:

```bash
PSQL_HOST=localhost
PSQL_PORT=5433
PSQL_USER=postgres
PSQL_PASSWORD=...
PSQL_DB=relationships
```

Variables already set in the shell are left unchanged; `.env` only fills in missing keys.

### Tests

#### Smoke tests

A scripted walkthrough lives under `scripts/`:

```powershell
# Windows — pipes canned input into a fresh session (add --sqlite if built with -fpostgres)
Get-Content scripts\smoke-test-input.txt | cabal run myfirstsql -- --sqlite
```

```bash
# Unix-like shells
cabal run myfirstsql -- --sqlite < scripts/smoke-test-input.txt
```

`scripts/smoke-test.txt` documents the same flow with commentary for manual testing.

Because every `.db` is gitignored, new checkouts start from a clean slate, and there is no risk of leaking your data -unless you add an exception.
Remove or rename `relationships.db` if you want a clean slate (the renamed database will still be gitignored).

### Files layout

```
app/
  Main.hs          REPL loop
  Parse.hs         Command-line parsing
  Complete.hs      Interactive argument completion
  Prompt.hs        Entity pickers and creation helpers
  Run.hs           Execute actions against the database
  Types.hs         Domain types and action ADT
  Help.hs          Prompt and error formatting
  Db/              Backend dispatch per entity (Person, Company, …)
    Sqlite/        SQLite implementation (schema + per-entity modules)
    Postgres/      PostgreSQL implementation via Rel8/Hasql
    Conn.hs        Backend selection, .env loading, connection open/close
scripts/           Smoke-test input and transcript
myfirstsql.cabal   Package definition
```

`test.hs` at the repo root is a standalone sqlite-simple scratch file, not part of the executable.

## License

No license is specified yet (`license: NONE` in the Cabal file). Contact the maintainer before redistributing.

## Author

Francesco Dondi — francesco314@gmail.com
