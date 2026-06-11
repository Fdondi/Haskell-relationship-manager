{-# LANGUAGE OverloadedStrings #-}

module Db.Sqlite.Company
  ( addCompany
  , listCompanies
  , companyExists
  , deleteCompany
  , printCompanies
  ) where

import           Control.Exception (catch)
import           Database.SQLite.Simple
import           Db.Sqlite.Count (CountRow (..))
import           Types

addCompany :: Connection -> CompanyName -> CompanyNotes -> IO Int
addCompany conn name notes = do
  execute conn "INSERT INTO companies (name, notes) VALUES (?, ?)" (name, notes)
  fromIntegral <$> lastInsertRowId conn

listCompanies :: Connection -> IO [CompanyRow]
listCompanies conn = query_ conn "SELECT id, name, notes FROM companies ORDER BY id"

companyExists :: Connection -> Int -> IO Bool
companyExists conn id_ = do
  [CountRow n] <- query conn "SELECT COUNT(*) FROM companies WHERE id = ?" (Only id_)
  pure (n > 0)

deleteCompany :: Connection -> Int -> IO Bool
deleteCompany conn id_ =
  (do
    execute conn "DELETE FROM companies WHERE id = ?" (Only id_)
    putStrLn ("Company with ID " ++ show id_ ++ " deleted")
    pure True)
    `catch` \(_ :: SQLError) -> do
      putStrLn "Cannot delete company: still referenced by employment or sponsorship links"
      pure False

printCompanies :: Connection -> IO ()
printCompanies conn = do
  putStrLn "Companies:"
  rows <- listCompanies conn
  mapM_ print rows
