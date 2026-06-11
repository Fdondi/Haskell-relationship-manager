{-# LANGUAGE OverloadedStrings #-}

module Db.Person where

import           Control.Exception (catch)
import           Database.SQLite.Simple
import           Db.Count (CountRow (..))
import           Types

addPerson :: Connection -> PersonName -> PersonNotes -> [Int] -> IO Int
addPerson conn name notes companyIds = do
  execute conn "INSERT INTO people (name, notes) VALUES (?, ?)" (name, notes)
  personId <- fromIntegral <$> lastInsertRowId conn
  mapM_ (linkEmployment conn personId) companyIds
  pure personId

linkEmployment :: Connection -> Int -> Int -> IO ()
linkEmployment conn personId companyId =
  execute conn "INSERT OR IGNORE INTO person_companies (person_id, company_id) VALUES (?, ?)" (personId, companyId)

listPeople :: Connection -> IO [PersonRow]
listPeople conn = query_ conn "SELECT id, name, notes FROM people ORDER BY id"

personExists :: Connection -> Int -> IO Bool
personExists conn id_ = do
  [CountRow n] <- query conn "SELECT COUNT(*) FROM people WHERE id = ?" (Only id_)
  pure (n > 0)

deletePerson :: Connection -> Int -> IO Bool
deletePerson conn id_ =
  (do
    execute conn "DELETE FROM people WHERE id = ?" (Only id_)
    putStrLn ("Person with ID " ++ show id_ ++ " deleted")
    pure True)
    `catch` \(_ :: SQLError) -> do
      putStrLn "Cannot delete person: still referenced by encounters (delete those first)"
      pure False

printPeople :: Connection -> IO ()
printPeople conn = do
  putStrLn "People:"
  rows <- listPeople conn
  mapM_ print rows
