{-# LANGUAGE OverloadedStrings #-}

module Db.Sqlite.Schema
  ( dbPath
  , initSqliteDb
  , openSqliteDb
  ) where

import           Database.SQLite.Simple

dbPath :: String
dbPath = "relationships.db"

initSqliteDb :: Connection -> IO ()
initSqliteDb conn = do
  execute_ conn "PRAGMA foreign_keys = ON"
  execute_ conn "CREATE TABLE IF NOT EXISTS people (id INTEGER PRIMARY KEY, name TEXT NOT NULL, notes TEXT NOT NULL DEFAULT '')"
  execute_ conn "CREATE TABLE IF NOT EXISTS companies (id INTEGER PRIMARY KEY, name TEXT NOT NULL, notes TEXT NOT NULL DEFAULT '')"
  execute_ conn "CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY, location TEXT NOT NULL, start TEXT NOT NULL, end TEXT NOT NULL, notes TEXT NOT NULL DEFAULT '')"
  execute_ conn "CREATE TABLE IF NOT EXISTS encounters (id INTEGER PRIMARY KEY, person_id INTEGER NOT NULL REFERENCES people(id) ON DELETE RESTRICT, event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE RESTRICT, notes TEXT NOT NULL DEFAULT '')"
  execute_ conn "CREATE TABLE IF NOT EXISTS employment (person_id INTEGER NOT NULL REFERENCES people(id) ON DELETE CASCADE, company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE, PRIMARY KEY (person_id, company_id))"
  execute_ conn "CREATE TABLE IF NOT EXISTS sponsorship (event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE, company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE, PRIMARY KEY (event_id, company_id))"

openSqliteDb :: IO Connection
openSqliteDb = do
  conn <- open dbPath
  initSqliteDb conn
  pure conn
