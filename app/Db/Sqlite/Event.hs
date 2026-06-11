{-# LANGUAGE OverloadedStrings #-}

module Db.Sqlite.Event
  ( addEvent
  , linkSponsorship
  , listEvents
  , eventExists
  , deleteEvent
  , printEvents
  ) where

import           Control.Exception (catch)
import           Database.SQLite.Simple
import           Db.Sqlite.Count (CountRow (..))
import           Types

addEvent :: Connection -> EventLocation -> EventTime -> EventTime -> EventNotes -> [Int] -> IO Int
addEvent conn location start end notes sponsorIds = do
  execute conn "INSERT INTO events (location, start, end, notes) VALUES (?, ?, ?, ?)" (location, start, end, notes)
  eventId <- fromIntegral <$> lastInsertRowId conn
  mapM_ (linkSponsorship conn eventId) sponsorIds
  pure eventId

linkSponsorship :: Connection -> Int -> Int -> IO ()
linkSponsorship conn eventId companyId =
  execute conn "INSERT OR IGNORE INTO sponsorship (event_id, company_id) VALUES (?, ?)" (eventId, companyId)

listEvents :: Connection -> IO [EventRow]
listEvents conn = query_ conn "SELECT id, location, start, end, notes FROM events ORDER BY id"

eventExists :: Connection -> Int -> IO Bool
eventExists conn id_ = do
  [CountRow n] <- query conn "SELECT COUNT(*) FROM events WHERE id = ?" (Only id_)
  pure (n > 0)

deleteEvent :: Connection -> Int -> IO Bool
deleteEvent conn id_ =
  (do
    execute conn "DELETE FROM events WHERE id = ?" (Only id_)
    putStrLn ("Event with ID " ++ show id_ ++ " deleted")
    pure True)
    `catch` \(_ :: SQLError) -> do
      putStrLn "Cannot delete event: still referenced by encounters (delete those first)"
      pure False

printEvents :: Connection -> IO ()
printEvents conn = do
  putStrLn "Events:"
  rows <- listEvents conn
  mapM_ print rows
