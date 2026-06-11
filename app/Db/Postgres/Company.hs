{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module Db.Postgres.Company
  ( addCompany
  , listCompanies
  , companyExists
  , deleteCompany
  , printCompanies
  ) where

import           Data.Functor.Contravariant ((>$<))
import           Data.Text (Text)
import           Db.Postgres.Query
import           Db.Postgres.Schema
import           Rel8
import           Types

import qualified Hasql.Connection as Hasql

addCompany :: Hasql.Connection -> Text -> Text -> IO Int
addCompany conn name notes =
  insertReturningId conn $
    Insert
      { into = companySchema
      , rows = values [Company unsafeDefault (lit name) (lit notes)]
      , returning = Returning $ \c -> companyId c
      , onConflict = Abort
      }

listCompanies :: Hasql.Connection -> IO [CompanyRow]
listCompanies conn = do
  rows <-
    runQuery conn $
      select $
        orderBy (companyId >$< asc) $
          each companySchema
  pure [CompanyRow (fromIntegral (companyId r)) (companyName r) (companyNotes r) | r <- rows]

companyExists :: Hasql.Connection -> Int -> IO Bool
companyExists conn id_ = do
  rows <-
    runQuery conn $
      select $
        do
          c <- each companySchema
          where_ $ companyId c ==. lit (fromIntegral id_)
          return c
  pure (not (Prelude.null rows))

deleteCompany :: Hasql.Connection -> Int -> IO Bool
deleteCompany conn id_ =
  withFkGuard
    ( do
        runStatement_ conn $
          delete $
            Delete
              { from = companySchema
              , using = pure ()
              , deleteWhere = \_ c -> companyId c ==. lit (fromIntegral id_)
              , returning = NoReturning
              }
        putStrLn ("Company with ID " ++ show id_ ++ " deleted")
        pure True
    )
    "Cannot delete company: still referenced by employment or sponsorship links"

printCompanies :: Hasql.Connection -> IO ()
printCompanies conn = do
  putStrLn "Companies:"
  mapM_ print =<< listCompanies conn
