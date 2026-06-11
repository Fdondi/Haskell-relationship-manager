{-# LANGUAGE OverloadedStrings #-}

module Db.Links where

import           Database.SQLite.Simple
import           Db.Count (CountRow (..))
import           Types

addEmployment :: Connection -> Int -> Int -> IO Bool
addEmployment conn personId companyId = do
  execute conn "INSERT OR IGNORE INTO person_companies (person_id, company_id) VALUES (?, ?)" (personId, companyId)
  putStrLn "Employment link added (or already existed)"
  pure True

employmentExists :: Connection -> Int -> Int -> IO Bool
employmentExists conn personId companyId = do
  [CountRow n] <-
    query conn
      "SELECT COUNT(*) FROM person_companies WHERE person_id = ? AND company_id = ?"
      (personId, companyId)
  pure (n > 0)

deleteEmployment :: Connection -> Int -> Int -> IO Bool
deleteEmployment conn personId companyId = do
  existed <- employmentExists conn personId companyId
  execute conn "DELETE FROM person_companies WHERE person_id = ? AND company_id = ?" (personId, companyId)
  if existed
    then putStrLn "Employment link deleted" >> pure True
    else putStrLn "Employment link not found" >> pure True

listEmployment :: Connection -> IO [EmploymentRow]
listEmployment conn =
  query_ conn
    "SELECT pc.person_id, p.name, pc.company_id, c.name \
    \FROM person_companies pc \
    \JOIN people p ON p.id = pc.person_id \
    \JOIN companies c ON c.id = pc.company_id \
    \ORDER BY pc.person_id, pc.company_id"

printEmployment :: Connection -> IO ()
printEmployment conn = do
  putStrLn "Employment:"
  rows <- listEmployment conn
  mapM_ print rows

addSponsorship :: Connection -> Int -> Int -> IO Bool
addSponsorship conn eventId companyId = do
  execute conn "INSERT OR IGNORE INTO event_companies (event_id, company_id) VALUES (?, ?)" (eventId, companyId)
  putStrLn "Sponsorship link added (or already existed)"
  pure True

sponsorshipExists :: Connection -> Int -> Int -> IO Bool
sponsorshipExists conn eventId companyId = do
  [CountRow n] <-
    query conn
      "SELECT COUNT(*) FROM event_companies WHERE event_id = ? AND company_id = ?"
      (eventId, companyId)
  pure (n > 0)

deleteSponsorship :: Connection -> Int -> Int -> IO Bool
deleteSponsorship conn eventId companyId = do
  existed <- sponsorshipExists conn eventId companyId
  execute conn "DELETE FROM event_companies WHERE event_id = ? AND company_id = ?" (eventId, companyId)
  if existed
    then putStrLn "Sponsorship link deleted" >> pure True
    else putStrLn "Sponsorship link not found" >> pure True

listSponsorship :: Connection -> IO [SponsorshipRow]
listSponsorship conn =
  query_ conn
    "SELECT ec.event_id, e.location, ec.company_id, c.name \
    \FROM event_companies ec \
    \JOIN events e ON e.id = ec.event_id \
    \JOIN companies c ON c.id = ec.company_id \
    \ORDER BY ec.event_id, ec.company_id"

printSponsorship :: Connection -> IO ()
printSponsorship conn = do
  putStrLn "Sponsorship:"
  rows <- listSponsorship conn
  mapM_ print rows
