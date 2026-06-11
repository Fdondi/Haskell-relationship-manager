{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}

module Db.Person where

import           Db.Conn (DbConn (..))
import           Types

import qualified Db.Sqlite.Person as Sqlite

#ifdef POSTGRES
import qualified Db.Postgres.Person as Postgres
#endif

addPerson :: DbConn -> PersonName -> PersonNotes -> [Int] -> IO Int
addPerson (SqliteConn conn) name notes companyIds = Sqlite.addPerson conn name notes companyIds
#ifdef POSTGRES
addPerson (PostgresConn conn) name notes companyIds = Postgres.addPerson conn name notes companyIds
#endif

linkEmployment :: DbConn -> Int -> Int -> IO ()
linkEmployment (SqliteConn conn) personId companyId = Sqlite.linkEmployment conn personId companyId
#ifdef POSTGRES
linkEmployment (PostgresConn conn) personId companyId = Postgres.linkEmployment conn personId companyId
#endif

listPeople :: DbConn -> IO [PersonRow]
listPeople (SqliteConn conn) = Sqlite.listPeople conn
#ifdef POSTGRES
listPeople (PostgresConn conn) = Postgres.listPeople conn
#endif

personExists :: DbConn -> Int -> IO Bool
personExists (SqliteConn conn) = Sqlite.personExists conn
#ifdef POSTGRES
personExists (PostgresConn conn) = Postgres.personExists conn
#endif

deletePerson :: DbConn -> Int -> IO Bool
deletePerson (SqliteConn conn) = Sqlite.deletePerson conn
#ifdef POSTGRES
deletePerson (PostgresConn conn) = Postgres.deletePerson conn
#endif

printPeople :: DbConn -> IO ()
printPeople (SqliteConn conn) = Sqlite.printPeople conn
#ifdef POSTGRES
printPeople (PostgresConn conn) = Postgres.printPeople conn
#endif
