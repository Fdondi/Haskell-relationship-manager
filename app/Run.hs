{-# LANGUAGE LambdaCase #-}

module Run where

import           Db.Conn (DbConn)
import           Db.Company
import           Db.Encounter
import           Db.Event
import           Db.Links
import           Db.Person
import           Types

runAction :: DbConn -> Action -> IO Bool
runAction conn (AddPerson name notes companyIds) = do
  _ <- addPerson conn name notes companyIds
  putStrLn "Person added"
  pure True
runAction conn (AddCompany name notes) = do
  _ <- addCompany conn name notes
  putStrLn "Company added"
  pure True
runAction conn (AddEvent location start end notes sponsorIds) = do
  _ <- addEvent conn location start end notes sponsorIds
  putStrLn "Event added"
  pure True
runAction conn (AddEncounter personId eventId notes) = do
  _ <- addEncounter conn personId eventId notes
  putStrLn "Encounter added"
  pure True
runAction conn (AddEmployment personId companyId) =
  addEmployment conn personId companyId
runAction conn (AddSponsorship eventId companyId) =
  addSponsorship conn eventId companyId
runAction conn (ListEntity obj) = listEntity conn obj >> pure True
runAction conn (DeleteEntity obj id_) = deleteEntity conn obj id_
runAction conn (DeleteEmployment personId companyId) =
  deleteEmployment conn personId companyId
runAction conn (DeleteSponsorship eventId companyId) =
  deleteSponsorship conn eventId companyId
runAction _conn Quit = do
  putStrLn "Quitting..."
  pure False

listEntity :: DbConn -> ObjectKind -> IO ()
listEntity conn = \case
  OPerson      -> printPeople conn
  OCompany     -> printCompanies conn
  OEvent       -> printEvents conn
  OEncounter   -> printEncounters conn
  OEmployment  -> printEmployment conn
  OSponsorship -> printSponsorship conn

deleteEntity :: DbConn -> ObjectKind -> Int -> IO Bool
deleteEntity conn OPerson id_ = deletePerson conn id_
deleteEntity conn OCompany id_ = deleteCompany conn id_
deleteEntity conn OEvent id_ = deleteEvent conn id_
deleteEntity conn OEncounter id_ = deleteEncounter conn id_
deleteEntity _ OEmployment _ = do
  putStrLn "Use: delete employment <person_id> <company_id>"
  pure True
deleteEntity _ OSponsorship _ = do
  putStrLn "Use: delete sponsorship <event_id> <company_id>"
  pure True
