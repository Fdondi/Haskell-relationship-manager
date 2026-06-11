{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module Db.Postgres.Event
  ( addEvent
  , linkSponsorship
  , listEvents
  , eventExists
  , deleteEvent
  , printEvents
  ) where

import           Data.Functor.Contravariant ((>$<))
import           Data.Text (Text)
import           Db.Postgres.Query
import           Db.Postgres.Schema
import           Rel8
import           Types

import qualified Hasql.Connection as Hasql

addEvent :: Hasql.Connection -> Text -> Text -> Text -> Text -> [Int] -> IO Int
addEvent conn location start end notes sponsorIds = do
  eventId <-
    insertReturningId conn $
      Insert
        { into = eventSchema
        , rows =
            values
              [ Event unsafeDefault (lit location) (lit start) (lit end) (lit notes)
              ]
        , returning = Returning $ \e -> eventId e
        , onConflict = Abort
        }
  mapM_ (linkSponsorship conn eventId) sponsorIds
  pure eventId

linkSponsorship :: Hasql.Connection -> Int -> Int -> IO ()
linkSponsorship conn eventId companyId =
  runStatement_ conn $
    insert $
      Insert
        { into = sponsorshipSchema
        , rows =
            values
              [ Sponsorship (lit (fromIntegral eventId)) (lit (fromIntegral companyId))
              ]
        , returning = NoReturning
        , onConflict = DoNothing
        }

listEvents :: Hasql.Connection -> IO [EventRow]
listEvents conn = do
  rows <-
    runQuery conn $
      select $
        orderBy (eventId >$< asc) $
          each eventSchema
  pure
    [ EventRow
        (fromIntegral (eventId r))
        (eventLocation r)
        (eventStart r)
        (eventEnd r)
        (eventNotes r)
    | r <- rows
    ]

eventExists :: Hasql.Connection -> Int -> IO Bool
eventExists conn id_ = do
  rows <-
    runQuery conn $
      select $
        do
          e <- each eventSchema
          where_ $ eventId e ==. lit (fromIntegral id_)
          return e
  pure (not (Prelude.null rows))

deleteEvent :: Hasql.Connection -> Int -> IO Bool
deleteEvent conn id_ =
  withFkGuard
    ( do
        runStatement_ conn $
          delete $
            Delete
              { from = eventSchema
              , using = pure ()
              , deleteWhere = \_ e -> eventId e ==. lit (fromIntegral id_)
              , returning = NoReturning
              }
        putStrLn ("Event with ID " ++ show id_ ++ " deleted")
        pure True
    )
    "Cannot delete event: still referenced by encounters (delete those first)"

printEvents :: Hasql.Connection -> IO ()
printEvents conn = do
  putStrLn "Events:"
  mapM_ print =<< listEvents conn
