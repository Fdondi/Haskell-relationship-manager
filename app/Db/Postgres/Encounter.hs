{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module Db.Postgres.Encounter
  ( addEncounter
  , listEncounters
  , encounterExists
  , deleteEncounter
  , printEncounters
  ) where

import           Data.Functor.Contravariant ((>$<))
import           Data.Text (Text)
import           Db.Postgres.Query
import           Db.Postgres.Schema
import           Rel8
import           Types

import qualified Hasql.Connection as Hasql

addEncounter :: Hasql.Connection -> Int -> Int -> Text -> IO Int
addEncounter conn personId eventId notes =
  insertReturningId conn $
    Insert
      { into = encounterSchema
      , rows =
          values
            [ Encounter
                unsafeDefault
                (lit (fromIntegral personId))
                (lit (fromIntegral eventId))
                (lit notes)
            ]
      , returning = Returning $ \e -> encounterId e
      , onConflict = Abort
      }

listEncounters :: Hasql.Connection -> IO [EncounterRow]
listEncounters conn = do
  rows <-
    runQuery conn $
      select $
        orderBy (encounterId >$< asc) $
          each encounterSchema
  pure
    [ EncounterRow
        (fromIntegral (encounterId r))
        (fromIntegral (encounterPersonId r))
        (fromIntegral (encounterEventId r))
        (encounterNotes r)
    | r <- rows
    ]

encounterExists :: Hasql.Connection -> Int -> IO Bool
encounterExists conn id_ = do
  rows <-
    runQuery conn $
      select $
        do
          e <- each encounterSchema
          where_ $ encounterId e ==. lit (fromIntegral id_)
          return e
  pure (not (Prelude.null rows))

deleteEncounter :: Hasql.Connection -> Int -> IO Bool
deleteEncounter conn id_ = do
  runStatement_ conn $
    delete $
      Delete
        { from = encounterSchema
        , using = pure ()
        , deleteWhere = \_ e -> encounterId e ==. lit (fromIntegral id_)
        , returning = NoReturning
        }
  putStrLn ("Encounter with ID " ++ show id_ ++ " deleted")
  pure True

printEncounters :: Hasql.Connection -> IO ()
printEncounters conn = do
  putStrLn "Encounters:"
  mapM_ print =<< listEncounters conn
