{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}

module Db.Encounter where

import           Db.Conn (DbConn (..))
import           Types

import qualified Db.Sqlite.Encounter as Sqlite

#ifdef POSTGRES
import qualified Db.Postgres.Encounter as Postgres
#endif

addEncounter :: DbConn -> Int -> Int -> EncounterNotes -> IO Int
addEncounter (SqliteConn conn) = Sqlite.addEncounter conn
#ifdef POSTGRES
addEncounter (PostgresConn conn) = Postgres.addEncounter conn
#endif

listEncounters :: DbConn -> IO [EncounterRow]
listEncounters (SqliteConn conn) = Sqlite.listEncounters conn
#ifdef POSTGRES
listEncounters (PostgresConn conn) = Postgres.listEncounters conn
#endif

encounterExists :: DbConn -> Int -> IO Bool
encounterExists (SqliteConn conn) = Sqlite.encounterExists conn
#ifdef POSTGRES
encounterExists (PostgresConn conn) = Postgres.encounterExists conn
#endif

deleteEncounter :: DbConn -> Int -> IO Bool
deleteEncounter (SqliteConn conn) = Sqlite.deleteEncounter conn
#ifdef POSTGRES
deleteEncounter (PostgresConn conn) = Postgres.deleteEncounter conn
#endif

printEncounters :: DbConn -> IO ()
printEncounters (SqliteConn conn) = Sqlite.printEncounters conn
#ifdef POSTGRES
printEncounters (PostgresConn conn) = Postgres.printEncounters conn
#endif
