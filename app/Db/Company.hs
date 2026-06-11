{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}

module Db.Company where

import           Db.Conn (DbConn (..))
import           Types

import qualified Db.Sqlite.Company as Sqlite

#ifdef POSTGRES
import qualified Db.Postgres.Company as Postgres
#endif

addCompany :: DbConn -> CompanyName -> CompanyNotes -> IO Int
addCompany (SqliteConn conn) = Sqlite.addCompany conn
#ifdef POSTGRES
addCompany (PostgresConn conn) = Postgres.addCompany conn
#endif

listCompanies :: DbConn -> IO [CompanyRow]
listCompanies (SqliteConn conn) = Sqlite.listCompanies conn
#ifdef POSTGRES
listCompanies (PostgresConn conn) = Postgres.listCompanies conn
#endif

companyExists :: DbConn -> Int -> IO Bool
companyExists (SqliteConn conn) = Sqlite.companyExists conn
#ifdef POSTGRES
companyExists (PostgresConn conn) = Postgres.companyExists conn
#endif

deleteCompany :: DbConn -> Int -> IO Bool
deleteCompany (SqliteConn conn) = Sqlite.deleteCompany conn
#ifdef POSTGRES
deleteCompany (PostgresConn conn) = Postgres.deleteCompany conn
#endif

printCompanies :: DbConn -> IO ()
printCompanies (SqliteConn conn) = Sqlite.printCompanies conn
#ifdef POSTGRES
printCompanies (PostgresConn conn) = Postgres.printCompanies conn
#endif
