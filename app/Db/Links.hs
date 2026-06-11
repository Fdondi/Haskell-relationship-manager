{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}

module Db.Links where

import           Db.Conn (DbConn (..))
import           Types

import qualified Db.Sqlite.Links as Sqlite

#ifdef POSTGRES
import qualified Db.Postgres.Links as Postgres
#endif

addEmployment :: DbConn -> Int -> Int -> IO Bool
addEmployment (SqliteConn conn) = Sqlite.addEmployment conn
#ifdef POSTGRES
addEmployment (PostgresConn conn) = Postgres.addEmployment conn
#endif

employmentExists :: DbConn -> Int -> Int -> IO Bool
employmentExists (SqliteConn conn) = Sqlite.employmentExists conn
#ifdef POSTGRES
employmentExists (PostgresConn conn) = Postgres.employmentExists conn
#endif

deleteEmployment :: DbConn -> Int -> Int -> IO Bool
deleteEmployment (SqliteConn conn) = Sqlite.deleteEmployment conn
#ifdef POSTGRES
deleteEmployment (PostgresConn conn) = Postgres.deleteEmployment conn
#endif

listEmployment :: DbConn -> IO [EmploymentRow]
listEmployment (SqliteConn conn) = Sqlite.listEmployment conn
#ifdef POSTGRES
listEmployment (PostgresConn conn) = Postgres.listEmployment conn
#endif

printEmployment :: DbConn -> IO ()
printEmployment (SqliteConn conn) = Sqlite.printEmployment conn
#ifdef POSTGRES
printEmployment (PostgresConn conn) = Postgres.printEmployment conn
#endif

addSponsorship :: DbConn -> Int -> Int -> IO Bool
addSponsorship (SqliteConn conn) = Sqlite.addSponsorship conn
#ifdef POSTGRES
addSponsorship (PostgresConn conn) = Postgres.addSponsorship conn
#endif

sponsorshipExists :: DbConn -> Int -> Int -> IO Bool
sponsorshipExists (SqliteConn conn) = Sqlite.sponsorshipExists conn
#ifdef POSTGRES
sponsorshipExists (PostgresConn conn) = Postgres.sponsorshipExists conn
#endif

deleteSponsorship :: DbConn -> Int -> Int -> IO Bool
deleteSponsorship (SqliteConn conn) = Sqlite.deleteSponsorship conn
#ifdef POSTGRES
deleteSponsorship (PostgresConn conn) = Postgres.deleteSponsorship conn
#endif

listSponsorship :: DbConn -> IO [SponsorshipRow]
listSponsorship (SqliteConn conn) = Sqlite.listSponsorship conn
#ifdef POSTGRES
listSponsorship (PostgresConn conn) = Postgres.listSponsorship conn
#endif

printSponsorship :: DbConn -> IO ()
printSponsorship (SqliteConn conn) = Sqlite.printSponsorship conn
#ifdef POSTGRES
printSponsorship (PostgresConn conn) = Postgres.printSponsorship conn
#endif
