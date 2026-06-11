{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedStrings #-}

module Db.Postgres.Query
  ( runQuery
  , runStatement_
  , withFkGuard
  , insertReturningId
  ) where

import           Control.Exception (catch, displayException)
import           Data.Int (Int64)
import           Data.List (isInfixOf)
import           Rel8

import qualified Hasql.Connection as Hasql
import qualified Hasql.Session as Session

runQuery :: Serializable exprs a => Hasql.Connection -> Statement (Query exprs) -> IO [a]
runQuery conn stmt = do
  result <- Session.run (Session.statement () (run stmt)) conn
  case result of
    Right rows -> pure rows
    Left err -> error ("PostgreSQL query failed: " ++ show err)

runStatement_ :: Hasql.Connection -> Statement a -> IO ()
runStatement_ conn stmt = do
  result <- Session.run (Session.statement () (run_ stmt)) conn
  case result of
    Right () -> pure ()
    Left err -> error ("PostgreSQL statement failed: " ++ show err)

isForeignKeyViolation :: Session.SessionError -> Bool
isForeignKeyViolation err = "23503" `isInfixOf` displayException err

withFkGuard :: IO Bool -> String -> IO Bool
withFkGuard action msg =
  action `catch` \err ->
    if isForeignKeyViolation err
      then putStrLn msg >> pure False
      else error ("PostgreSQL error: " ++ displayException (err :: Session.SessionError))

insertReturningId :: Hasql.Connection -> Insert (Query (Expr Int64)) -> IO Int
insertReturningId conn ins = do
  (id_ : _) <- runQuery conn (insert ins)
  pure (fromIntegral id_)
