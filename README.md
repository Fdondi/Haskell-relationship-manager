# myfirstsql

An interactive command-line tool for tracking people, companies, events, and how they connect. Data is stored locally in SQLite.

Built in Haskell as a proof of concept for a real world program, with both user and DB I/O.

## Features

- **Modelled Entities:** people, companies, events, encounters (person at an event), employment links, sponsorship links
- **CRUD from the REPL:** `add`, `list`, and `delete` for each entity type
- **Interactive completion:** omit arguments and the program asks for them; pick existing records by id or type `new` to create one on the spot
- **Referential integrity:** foreign keys enforced; deletes are blocked when dependent rows still exist
- **Persistent storage:** a single SQLite file in the project directory

## Requirements

- [GHC](https://www.haskell.org/ghc/) 9.6+ (GHC2021)
- [Cabal](https://www.haskell.org/cabal/) 3.x

Dependencies (`sqlite-simple`, `text`, `unordered-containers`) are resolved by Cabal from Hackage.

## Build and run

```bash
cabal build
cabal run myfirstsql
```

On first launch the program creates `relationships.db` in the current working directory and applies the schema.

## Command format

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

### Examples

```
add person "Jane Doe"
add company "Acme Corp"
list person
delete encounter 3
delete employment 1 2
quit
```

### Partial commands

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

### Delete behavior

| Target | Syntax | Notes |
|--------|--------|-------|
| Person, company, event, encounter | `delete <object> <id>` | Person/event deletes fail while encounters still reference them |
| Employment | `delete employment <person_id> <company_id>` | Removes one link, not the person or company |
| Sponsorship | `delete sponsorship <event_id> <company_id>` | Removes one link, not the event or company |

Invalid input prints a short error and redisplays the available actions and objects.

## Data model

```
people ──┬── encounters ── events
         │                    │
         └── person_companies └── event_companies
                    │                    │
                companies ───────────────┘
```

| Table | Purpose |
|-------|---------|
| `people` | Name and notes |
| `companies` | Name and notes |
| `events` | Location, start/end (free-text), notes |
| `encounters` | A person at an event, with notes |
| `person_companies` | Employment: many-to-many person ↔ company |
| `event_companies` | Sponsorship: many-to-many event ↔ company |

`PRAGMA foreign_keys = ON` is set on every connection.

## Smoke test

A scripted walkthrough lives under `scripts/`:

```powershell
# Windows — pipes canned input into a fresh session
Get-Content scripts\smoke-test-input.txt | cabal run myfirstsql
```

```bash
# Unix-like shells
cabal run myfirstsql < scripts/smoke-test-input.txt
```

`scripts/smoke-test.txt` documents the same flow with commentary for manual testing.

Because every `.db` is gitignored, new checkouts start from a clean slate, and there is no risk of leaking your data -unless you add an exception.
Remove or rename `relationships.db` if you want a clean slate (the renamed database will still be gitignored).

## Project layout

```
app/
  Main.hs          REPL loop
  Parse.hs         Command-line parsing
  Complete.hs      Interactive argument completion
  Prompt.hs        Entity pickers and creation helpers
  Run.hs           Execute actions against the database
  Types.hs         Domain types and action ADT
  Help.hs          Prompt and error formatting
  Db/              SQLite access per entity
scripts/           Smoke-test input and transcript
myfirstsql.cabal   Package definition
```

`test.hs` at the repo root is a standalone sqlite-simple scratch file, not part of the executable.

## License

No license is specified yet (`license: NONE` in the Cabal file). Contact the maintainer before redistributing.

## Author

Francesco Dondi — francesco314@gmail.com
