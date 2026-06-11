{-# LANGUAGE OverloadedStrings #-}

module Db.Sqlite.Links
  ( addEmployment
  , employmentExists
  , deleteEmployment
  , listEmployment
  , printEmployment
  , addSponsorship
  , sponsorshipExists
  , deleteSponsorship
  , listSponsorship
  , printSponsorship
  ) where

import           Database.SQLite.Simple
import           Db.Sqlite.Count (CountRow (..))
import           Types

addEmployment :: Connection -> Int -> Int -> IO Bool
addEmployment conn personId companyId = do
  execute conn "INSERT OR IGNORE INTO employment (person_id, company_id) VALUES (?, ?)" (personId, companyId)
  putStrLn "Employment link added (or already existed)"
  pure True

employmentExists :: Connection -> Int -> Int -> IO Bool
employmentExists conn personId companyId = do
  [CountRow n] <-
    query conn
      "SELECT COUNT(*) FROM employment WHERE person_id = ? AND company_id = ?"
      (personId, companyId)
  pure (n > 0)

deleteEmployment :: Connection -> Int -> Int -> IO Bool
deleteEmployment conn personId companyId = do
  existed <- employmentExists conn personId companyId
  execute conn "DELETE FROM employment WHERE person_id = ? AND company_id = ?" (personId, companyId)
  if existed
    then putStrLn "Employment link deleted" >> pure True
    else putStrLn "Employment link not found" >> pure True

listEmployment :: Connection -> IO [EmploymentRow]
listEmployment conn =
  query_ conn "SELECT e.person_id, p.name, e.company_id, c.name FROM employment e JOIN people p ON p.id = e.person_id JOIN companies c ON c.id = e.company_id ORDER BY e.person_id, e.company_id"

printEmployment :: Connection -> IO ()
printEmployment conn = do
  putStrLn "Employment:"
  rows <- listEmployment conn
  mapM_ print rows

addSponsorship :: Connection -> Int -> Int -> IO Bool
addSponsorship conn eventId companyId = do
  execute conn "INSERT OR IGNORE INTO sponsorship (event_id, company_id) VALUES (?, ?)" (eventId, companyId)
  putStrLn "Sponsorship link added (or already existed)"
  pure True

sponsorshipExists :: Connection -> Int -> Int -> IO Bool
sponsorshipExists conn eventId companyId = do
  [CountRow n] <-
    query conn
      "SELECT COUNT(*) FROM sponsorship WHERE event_id = ? AND company_id = ?"
      (eventId, companyId)
  pure (n > 0)

deleteSponsorship :: Connection -> Int -> Int -> IO Bool
deleteSponsorship conn eventId companyId = do
  existed <- sponsorshipExists conn eventId companyId
  execute conn "DELETE FROM sponsorship WHERE event_id = ? AND company_id = ?" (eventId, companyId)
  if existed
    then putStrLn "Sponsorship link deleted" >> pure True
    else putStrLn "Sponsorship link not found" >> pure True

listSponsorship :: Connection -> IO [SponsorshipRow]
listSponsorship conn =
  query_ conn "SELECT s.event_id, ev.location, s.company_id, c.name FROM sponsorship s JOIN events ev ON ev.id = s.event_id JOIN companies c ON c.id = s.company_id ORDER BY s.event_id, s.company_id"

printSponsorship :: Connection -> IO ()
printSponsorship conn = do
  putStrLn "Sponsorship:"
  rows <- listSponsorship conn
  mapM_ print rows
