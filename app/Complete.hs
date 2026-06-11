{-# LANGUAGE OverloadedStrings #-}

module Complete where

import           Data.Char (toLower)
import qualified Data.Text as T
import           Database.SQLite.Simple
import           Prompt
import           Types

completeAction :: Connection -> ActionInput -> IO Action
completeAction conn (AddPersonInput mName) = do
  nameStr <- getIfMissing mName "Enter name: "
  putStrLn "Enter notes: "
  notesStr <- getLine
  putStrLn "Add employers now? (y/n)"
  addEmployers <- (/= "n") . map toLower <$> getLine
  companyIds <-
    if addEmployers
      then pickEntitiesOrCreate conn OCompany
      else pure []
  pure (AddPerson (T.pack nameStr) (T.pack notesStr) companyIds)
completeAction _conn (AddCompanyInput mName) = do
  nameStr <- getIfMissing mName "Enter name: "
  putStrLn "Enter notes: "
  notesStr <- getLine
  pure (AddCompany (T.pack nameStr) (T.pack notesStr))
completeAction conn (AddEventInput mLocation) = do
  locationStr <- getIfMissing mLocation "Enter location: "
  putStrLn "Enter start: "
  startStr <- getLine
  putStrLn "Enter end: "
  endStr <- getLine
  putStrLn "Enter notes: "
  notesStr <- getLine
  putStrLn "Add sponsors now? (y/n)"
  addSponsors <- (/= "n") . map toLower <$> getLine
  sponsorIds <-
    if addSponsors
      then pickEntitiesOrCreate conn OCompany
      else pure []
  pure (AddEvent (T.pack locationStr) (T.pack startStr) (T.pack endStr) (T.pack notesStr) sponsorIds)
completeAction conn AddEncounterInput = do
  personId <- pickEntityOrCreate conn OPerson
  eventId <- pickEntityOrCreate conn OEvent
  putStrLn "Enter notes: "
  notesStr <- getLine
  pure (AddEncounter personId eventId (T.pack notesStr))
completeAction conn AddEmploymentInput = do
  (personId, companyId) <- pickTwoIds conn OPerson OCompany
  pure (AddEmployment personId companyId)
completeAction conn AddSponsorshipInput = do
  (eventId, companyId) <- pickTwoIds conn OEvent OCompany
  pure (AddSponsorship eventId companyId)
completeAction _ (ListEntityInput obj) = pure (ListEntity obj)
completeAction _conn (DeleteEntityInput obj mId) = do
  id_ <- getIfMissing mId ("Enter " ++ objectKey obj ++ " id to delete: ")
  pure (DeleteEntity obj id_)
completeAction conn (DeleteEmploymentInput mPerson mCompany) = do
  (personId, companyId) <- getTwoIds mPerson mCompany conn OPerson OCompany
  pure (DeleteEmployment personId companyId)
completeAction conn (DeleteSponsorshipInput mEvent mCompany) = do
  (eventId, companyId) <- getTwoIds mEvent mCompany conn OEvent OCompany
  pure (DeleteSponsorship eventId companyId)
completeAction _ QuitInput = pure Quit
