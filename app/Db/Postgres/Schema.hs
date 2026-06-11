{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}

module Db.Postgres.Schema where

import           Data.ByteString.Char8 (pack)
import           Data.Int (Int64)
import           Data.Text (Text)
import           GHC.Generics (Generic)
import           Rel8

import qualified Hasql.Connection as Hasql
import qualified Hasql.Session as Session

data Person f = Person
  { personId :: Column f Int64
  , personName :: Column f Text
  , personNotes :: Column f Text
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (Person f)

personSchema :: TableSchema (Person Name)
personSchema =
  TableSchema
    { name = "people"
    , columns =
        Person
          { personId = "id"
          , personName = "name"
          , personNotes = "notes"
          }
    }

data Company f = Company
  { companyId :: Column f Int64
  , companyName :: Column f Text
  , companyNotes :: Column f Text
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (Company f)

companySchema :: TableSchema (Company Name)
companySchema =
  TableSchema
    { name = "companies"
    , columns =
        Company
          { companyId = "id"
          , companyName = "name"
          , companyNotes = "notes"
          }
    }

data Event f = Event
  { eventId :: Column f Int64
  , eventLocation :: Column f Text
  , eventStart :: Column f Text
  , eventEnd :: Column f Text
  , eventNotes :: Column f Text
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (Event f)

eventSchema :: TableSchema (Event Name)
eventSchema =
  TableSchema
    { name = "events"
    , columns =
        Event
          { eventId = "id"
          , eventLocation = "location"
          , eventStart = "\"start\""
          , eventEnd = "\"end\""
          , eventNotes = "notes"
          }
    }

data Encounter f = Encounter
  { encounterId :: Column f Int64
  , encounterPersonId :: Column f Int64
  , encounterEventId :: Column f Int64
  , encounterNotes :: Column f Text
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (Encounter f)

encounterSchema :: TableSchema (Encounter Name)
encounterSchema =
  TableSchema
    { name = "encounters"
    , columns =
        Encounter
          { encounterId = "id"
          , encounterPersonId = "person_id"
          , encounterEventId = "event_id"
          , encounterNotes = "notes"
          }
    }

data Employment f = Employment
  { employmentPersonId :: Column f Int64
  , employmentCompanyId :: Column f Int64
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (Employment f)

employmentSchema :: TableSchema (Employment Name)
employmentSchema =
  TableSchema
    { name = "employment"
    , columns =
        Employment
          { employmentPersonId = "person_id"
          , employmentCompanyId = "company_id"
          }
    }

data Sponsorship f = Sponsorship
  { sponsorshipEventId :: Column f Int64
  , sponsorshipCompanyId :: Column f Int64
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (Sponsorship f)

sponsorshipSchema :: TableSchema (Sponsorship Name)
sponsorshipSchema =
  TableSchema
    { name = "sponsorship"
    , columns =
        Sponsorship
          { sponsorshipEventId = "event_id"
          , sponsorshipCompanyId = "company_id"
          }
    }

data EmploymentJoin f = EmploymentJoin
  { ejPersonId :: Column f Int64
  , ejPersonName :: Column f Text
  , ejCompanyId :: Column f Int64
  , ejCompanyName :: Column f Text
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

data SponsorshipJoin f = SponsorshipJoin
  { sjEventId :: Column f Int64
  , sjEventLocation :: Column f Text
  , sjCompanyId :: Column f Int64
  , sjCompanyName :: Column f Text
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

initPostgresDb :: Hasql.Connection -> IO ()
initPostgresDb conn = mapM_ (runDdl conn) ddlStatements

ddlStatements :: [String]
ddlStatements =
  [ "CREATE TABLE IF NOT EXISTS people (id SERIAL PRIMARY KEY, name TEXT NOT NULL, notes TEXT NOT NULL DEFAULT '')"
  , "CREATE TABLE IF NOT EXISTS companies (id SERIAL PRIMARY KEY, name TEXT NOT NULL, notes TEXT NOT NULL DEFAULT '')"
  , "CREATE TABLE IF NOT EXISTS events (id SERIAL PRIMARY KEY, location TEXT NOT NULL, \"start\" TEXT NOT NULL, \"end\" TEXT NOT NULL, notes TEXT NOT NULL DEFAULT '')"
  , "CREATE TABLE IF NOT EXISTS encounters (id SERIAL PRIMARY KEY, person_id INTEGER NOT NULL REFERENCES people(id) ON DELETE RESTRICT, event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE RESTRICT, notes TEXT NOT NULL DEFAULT '')"
  , "CREATE TABLE IF NOT EXISTS employment (person_id INTEGER NOT NULL REFERENCES people(id) ON DELETE CASCADE, company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE, PRIMARY KEY (person_id, company_id))"
  , "CREATE TABLE IF NOT EXISTS sponsorship (event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE, company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE, PRIMARY KEY (event_id, company_id))"
  ]

runDdl :: Hasql.Connection -> String -> IO ()
runDdl conn sql = do
  result <- Session.run (Session.sql (pack sql)) conn
  case result of
    Right () -> pure ()
    Left err -> error ("PostgreSQL schema init failed: " ++ show err)
