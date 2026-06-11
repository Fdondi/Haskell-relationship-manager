{-# LANGUAGE OverloadedStrings #-}

module Db.Encounter where

import           Database.SQLite.Simple
import           Db.Count (CountRow (..))
import           Types

addEncounter :: Connection -> Int -> Int -> EncounterNotes -> IO Int
addEncounter conn personId eventId notes = do
  execute conn "INSERT INTO encounters (person_id, event_id, notes) VALUES (?, ?, ?)" (personId, eventId, notes)
  fromIntegral <$> lastInsertRowId conn

listEncounters :: Connection -> IO [EncounterRow]
listEncounters conn = query_ conn "SELECT id, person_id, event_id, notes FROM encounters ORDER BY id"

encounterExists :: Connection -> Int -> IO Bool
encounterExists conn id_ = do
  [CountRow n] <- query conn "SELECT COUNT(*) FROM encounters WHERE id = ?" (Only id_)
  pure (n > 0)

deleteEncounter :: Connection -> Int -> IO Bool
deleteEncounter conn id_ = do
  execute conn "DELETE FROM encounters WHERE id = ?" (Only id_)
  putStrLn ("Encounter with ID " ++ show id_ ++ " deleted")
  pure True

printEncounters :: Connection -> IO ()
printEncounters conn = do
  putStrLn "Encounters:"
  rows <- listEncounters conn
  mapM_ print rows
