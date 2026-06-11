{-# LANGUAGE OverloadedStrings #-}

module Types where

import           Database.SQLite.Simple
import qualified Data.Text as T

type PersonName = T.Text
type PersonNotes = T.Text
type CompanyName = T.Text
type CompanyNotes = T.Text
type EventLocation = T.Text
type EventTime = T.Text
type EventNotes = T.Text
type EncounterNotes = T.Text

data PersonRow = PersonRow Int PersonName PersonNotes deriving (Show)

instance FromRow PersonRow where
  fromRow = PersonRow <$> field <*> field <*> field

instance ToRow PersonRow where
  toRow (PersonRow id_ name notes) = toRow (id_, name, notes)

data CompanyRow = CompanyRow Int CompanyName CompanyNotes deriving (Show)

instance FromRow CompanyRow where
  fromRow = CompanyRow <$> field <*> field <*> field

instance ToRow CompanyRow where
  toRow (CompanyRow id_ name notes) = toRow (id_, name, notes)

data EventRow = EventRow Int EventLocation EventTime EventTime EventNotes deriving (Show)

instance FromRow EventRow where
  fromRow = EventRow <$> field <*> field <*> field <*> field <*> field

instance ToRow EventRow where
  toRow (EventRow id_ loc start end notes) = toRow (id_, loc, start, end, notes)

data EncounterRow = EncounterRow Int Int Int EncounterNotes deriving (Show)

instance FromRow EncounterRow where
  fromRow = EncounterRow <$> field <*> field <*> field <*> field

data EmploymentRow = EmploymentRow Int PersonName Int CompanyName deriving (Show)

instance FromRow EmploymentRow where
  fromRow = EmploymentRow <$> field <*> field <*> field <*> field

data SponsorshipRow = SponsorshipRow Int EventLocation Int CompanyName deriving (Show)

instance FromRow SponsorshipRow where
  fromRow = SponsorshipRow <$> field <*> field <*> field <*> field

data Verb = VAdd | VList | VDelete | VQuit deriving (Show, Eq, Enum, Bounded)

allowedVerbs :: [Verb]
allowedVerbs = [minBound .. maxBound]

verbKey :: Verb -> String
verbKey VAdd = "add"
verbKey VList = "list"
verbKey VDelete = "delete"
verbKey VQuit = "quit"

data ObjectKind
  = OPerson
  | OCompany
  | OEvent
  | OEncounter
  | OEmployment
  | OSponsorship
  deriving (Show, Eq, Enum, Bounded)

allowedObjects :: [ObjectKind]
allowedObjects = [minBound .. maxBound]

objectKey :: ObjectKind -> String
objectKey OPerson = "person"
objectKey OCompany = "company"
objectKey OEvent = "event"
objectKey OEncounter = "encounter"
objectKey OEmployment = "employment"
objectKey OSponsorship = "sponsorship"

data Action
  = AddPerson PersonName PersonNotes [Int]
  | AddCompany CompanyName CompanyNotes
  | AddEvent EventLocation EventTime EventTime EventNotes [Int]
  | AddEncounter Int Int EncounterNotes
  | AddEmployment Int Int
  | AddSponsorship Int Int
  | DeleteEntity ObjectKind Int
  | DeleteEmployment Int Int
  | DeleteSponsorship Int Int
  | ListEntity ObjectKind
  | Quit
  deriving (Show)

data ActionInput
  = AddPersonInput (Maybe String)
  | AddCompanyInput (Maybe String)
  | AddEventInput (Maybe String)
  | AddEncounterInput
  | AddEmploymentInput
  | AddSponsorshipInput
  | DeleteEntityInput ObjectKind (Maybe Int)
  | DeleteEmploymentInput (Maybe Int) (Maybe Int)
  | DeleteSponsorshipInput (Maybe Int) (Maybe Int)
  | ListEntityInput ObjectKind
  | QuitInput
  deriving (Show)
