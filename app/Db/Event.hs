{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}

module Db.Event where

import           Db.Conn (DbConn (..))
import           Types

import qualified Db.Sqlite.Event as Sqlite

#ifdef POSTGRES
import qualified Db.Postgres.Event as Postgres
#endif

addEvent :: DbConn -> EventLocation -> EventTime -> EventTime -> EventNotes -> [Int] -> IO Int
addEvent (SqliteConn conn) = Sqlite.addEvent conn
#ifdef POSTGRES
addEvent (PostgresConn conn) = Postgres.addEvent conn
#endif

linkSponsorship :: DbConn -> Int -> Int -> IO ()
linkSponsorship (SqliteConn conn) = Sqlite.linkSponsorship conn
#ifdef POSTGRES
linkSponsorship (PostgresConn conn) = Postgres.linkSponsorship conn
#endif

listEvents :: DbConn -> IO [EventRow]
listEvents (SqliteConn conn) = Sqlite.listEvents conn
#ifdef POSTGRES
listEvents (PostgresConn conn) = Postgres.listEvents conn
#endif

eventExists :: DbConn -> Int -> IO Bool
eventExists (SqliteConn conn) = Sqlite.eventExists conn
#ifdef POSTGRES
eventExists (PostgresConn conn) = Postgres.eventExists conn
#endif

deleteEvent :: DbConn -> Int -> IO Bool
deleteEvent (SqliteConn conn) = Sqlite.deleteEvent conn
#ifdef POSTGRES
deleteEvent (PostgresConn conn) = Postgres.deleteEvent conn
#endif

printEvents :: DbConn -> IO ()
printEvents (SqliteConn conn) = Sqlite.printEvents conn
#ifdef POSTGRES
printEvents (PostgresConn conn) = Postgres.printEvents conn
#endif
