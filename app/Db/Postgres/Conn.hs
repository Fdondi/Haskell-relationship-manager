{-# LANGUAGE OverloadedStrings #-}

module Db.Postgres.Conn (openConnection) where

import           Data.ByteString.Char8 (pack)
import           Data.Maybe (fromMaybe)
import           Db.Postgres.Schema (initPostgresDb)
import           System.Environment (lookupEnv)

import qualified Hasql.Connection as Hasql

openConnection :: String -> Int -> IO Hasql.Connection
openConnection host port = do
  user <- lookupEnvDefault "PSQL_USER" "postgres"
  password <- lookupEnvDefault "PSQL_PASSWORD" ""
  db <- lookupEnvDefault "PSQL_DB" "relationships"
  let connStr =
        "host=" ++ host
          ++ " port="
          ++ show port
          ++ " user="
          ++ user
          ++ " password="
          ++ password
          ++ " dbname="
          ++ db
  result <- Hasql.acquire (pack connStr)
  case result of
    Left err -> error ("PostgreSQL connection failed: " ++ show err)
    Right conn -> initPostgresDb conn >> pure conn

lookupEnvDefault :: String -> String -> IO String
lookupEnvDefault key fallback = fromMaybe fallback <$> lookupEnv key
