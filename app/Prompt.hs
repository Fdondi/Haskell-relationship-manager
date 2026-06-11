{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Prompt where

import           Data.Char (isSpace)
import qualified Data.Text as T
import           Db.Conn (DbConn)
import           Db.Company
import           Db.Encounter
import           Db.Event
import           Db.Links
import           Db.Person
import           Parse (parseObject, trim)
import           Types

getIfMissing :: Read a => Maybe a -> String -> IO a
getIfMissing (Just a) _ = pure a
getIfMissing Nothing prompt = do
  putStrLn prompt
  read <$> getLine

getLineText :: String -> IO T.Text
getLineText prompt = do
  putStrLn prompt
  T.pack <$> getLine

pickObjectKind :: IO ObjectKind
pickObjectKind = loop
  where
    loop = do
      putStrLn ("Enter object (" ++ unwords (map objectKey allowedObjects) ++ "):")
      input <- getLine
      case parseObject (trim input) of
        Just obj -> pure obj
        Nothing -> do
          putStrLn "Unknown object. Try again:"
          loop

printObjectList :: DbConn -> ObjectKind -> IO ()
printObjectList conn = \case
  OPerson      -> printPeople conn
  OCompany     -> printCompanies conn
  OEvent       -> printEvents conn
  OEncounter   -> printEncounters conn
  OEmployment  -> printEmployment conn
  OSponsorship -> printSponsorship conn

entityExists :: DbConn -> ObjectKind -> Int -> IO Bool
entityExists conn = \case
  OPerson      -> personExists conn
  OCompany     -> companyExists conn
  OEvent       -> eventExists conn
  OEncounter   -> encounterExists conn
  OEmployment  -> \_ -> pure False
  OSponsorship -> \_ -> pure False

createMinimal :: DbConn -> ObjectKind -> IO Int
createMinimal conn OPerson = do
  name <- getLineText "Enter name: "
  notes <- getLineText "Enter notes: "
  addPerson conn name notes []
createMinimal conn OCompany = do
  name <- getLineText "Enter name: "
  notes <- getLineText "Enter notes: "
  addCompany conn name notes
createMinimal conn OEvent = do
  location <- getLineText "Enter location: "
  start <- getLineText "Enter start: "
  end <- getLineText "Enter end: "
  notes <- getLineText "Enter notes: "
  addEvent conn location start end notes []
createMinimal conn OEncounter = do
  personId <- pickEntityOrCreate conn OPerson
  eventId <- pickEntityOrCreate conn OEvent
  notes <- getLineText "Enter notes: "
  addEncounter conn personId eventId notes
createMinimal conn OEmployment = do
  personId <- pickEntityOrCreate conn OPerson
  companyId <- pickEntityOrCreate conn OCompany
  _ <- addEmployment conn personId companyId
  pure personId
createMinimal conn OSponsorship = do
  eventId <- pickEntityOrCreate conn OEvent
  companyId <- pickEntityOrCreate conn OCompany
  _ <- addSponsorship conn eventId companyId
  pure eventId

pickEntityOrCreate :: DbConn -> ObjectKind -> IO Int
pickEntityOrCreate conn kind = do
  printObjectList conn kind
  putStrLn ("Enter " ++ objectKey kind ++ " id, or 'new' to create one:")
  loop
  where
    loop = do
      input <- getLine
      case trim input of
        "new" -> createMinimal conn kind
        s ->
          case reads s :: [(Int, String)] of
            [(n, rest)] | all isSpace rest -> do
              ok <- entityExists conn kind n
              if ok
                then pure n
                else do
                  putStrLn ("No " ++ objectKey kind ++ " with that id. Try again:")
                  loop
            _ -> do
              putStrLn "Enter a numeric id or 'new':"
              loop

pickEntitiesOrCreate :: DbConn -> ObjectKind -> IO [Int]
pickEntitiesOrCreate conn kind = do
  putStrLn ("Optional " ++ objectKey kind ++ " links (blank line when done):")
  printObjectList conn kind
  loop []
  where
    loop acc = do
      putStrLn "Enter id, 'new', or press Enter to finish:"
      input <- getLine
      case trim input of
        "" -> pure (reverse acc)
        "new" -> do
          id_ <- createMinimal conn kind
          loop (id_ : acc)
        s ->
          case reads s :: [(Int, String)] of
            [(n, rest)] | all isSpace rest -> do
              ok <- entityExists conn kind n
              if ok
                then loop (n : acc)
                else do
                  putStrLn ("No " ++ objectKey kind ++ " with that id. Try again:")
                  loop acc
            _ -> do
              putStrLn "Enter a numeric id, 'new', or blank:"
              loop acc

pickTwoIds :: DbConn -> ObjectKind -> ObjectKind -> IO (Int, Int)
pickTwoIds conn kind1 kind2 = do
  id1 <- pickEntityOrCreate conn kind1
  id2 <- pickEntityOrCreate conn kind2
  pure (id1, id2)

getTwoIds :: Maybe Int -> Maybe Int -> DbConn -> ObjectKind -> ObjectKind -> IO (Int, Int)
getTwoIds (Just a) (Just b) _ _ _ = pure (a, b)
getTwoIds _ _ conn kind1 kind2 = pickTwoIds conn kind1 kind2
