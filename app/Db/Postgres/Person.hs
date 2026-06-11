{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module Db.Postgres.Person
  ( addPerson
  , linkEmployment
  , listPeople
  , personExists
  , deletePerson
  , printPeople
  ) where

import           Data.Functor.Contravariant ((>$<))
import           Data.Text (Text)
import           Db.Postgres.Query
import           Db.Postgres.Schema
import           Rel8
import           Types

import qualified Hasql.Connection as Hasql

addPerson :: Hasql.Connection -> Text -> Text -> [Int] -> IO Int
addPerson conn name notes companyIds = do
  personId <-
    insertReturningId conn $
      Insert
        { into = personSchema
        , rows = values [Person unsafeDefault (lit name) (lit notes)]
        , returning = Returning $ \p -> personId p
        , onConflict = Abort
        }
  mapM_ (linkEmployment conn personId) companyIds
  pure personId

linkEmployment :: Hasql.Connection -> Int -> Int -> IO ()
linkEmployment conn personId companyId =
  runStatement_ conn $
    insert $
      Insert
        { into = employmentSchema
        , rows =
            values
              [ Employment (lit (fromIntegral personId)) (lit (fromIntegral companyId))
              ]
        , returning = NoReturning
        , onConflict = DoNothing
        }

listPeople :: Hasql.Connection -> IO [PersonRow]
listPeople conn = do
  rows <-
    runQuery conn $
      select $
        orderBy (personId >$< asc) $
          each personSchema
  pure [PersonRow (fromIntegral (personId r)) (personName r) (personNotes r) | r <- rows]

personExists :: Hasql.Connection -> Int -> IO Bool
personExists conn id_ = do
  rows <-
    runQuery conn $
      select $
        do
          p <- each personSchema
          where_ $ personId p ==. lit (fromIntegral id_)
          return p
  pure (not (Prelude.null rows))

deletePerson :: Hasql.Connection -> Int -> IO Bool
deletePerson conn id_ =
  withFkGuard
    ( do
        runStatement_ conn $
          delete $
            Delete
              { from = personSchema
              , using = pure ()
              , deleteWhere = \_ p -> personId p ==. lit (fromIntegral id_)
              , returning = NoReturning
              }
        putStrLn ("Person with ID " ++ show id_ ++ " deleted")
        pure True
    )
    "Cannot delete person: still referenced by encounters (delete those first)"

printPeople :: Hasql.Connection -> IO ()
printPeople conn = do
  putStrLn "People:"
  mapM_ print =<< listPeople conn
