{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Use newtype instead of data" #-}

module Db.Conn
  ( DbConn (..)
  , DbBackend (..)
  , parseDbBackend
  , loadDotEnv
  , openDb
  , closeDb
  ) where

import           Control.Exception (catch)
import           Control.Monad (when)
import           Data.Char (isSpace)
import           Data.List (dropWhileEnd, stripPrefix)
import           Data.Maybe (fromMaybe, isNothing)
import           Database.SQLite.Simple (Connection, close, open)
import           Db.Sqlite.Schema (dbPath, initSqliteDb)
import           System.Environment (lookupEnv, setEnv)
import           System.IO.Error (isDoesNotExistError)

#ifdef POSTGRES
import qualified Db.Postgres.Conn as Postgres
import qualified Hasql.Connection as Hasql
#endif

data DbBackend
  = SqliteBackend
#ifdef POSTGRES
  | PostgresBackend {pgHost :: String, pgPort :: Int}
#endif
  deriving (Show, Eq)

data DbConn
  = SqliteConn Connection
#ifdef POSTGRES
  | PostgresConn Hasql.Connection
#endif

loadDotEnv :: IO Bool
loadDotEnv = do
  result <-
    readFile ".env"
      `catch` \e ->
        if isDoesNotExistError e then pure "" else ioError e
  mapM_ applyEnvLine (lines result)
  pure True

applyEnvLine :: String -> IO ()
applyEnvLine line
  | null line || head line == '#' = pure ()
  | otherwise =
      case break (== '=') line of
        (key, '=' : val) -> do
          existing <- lookupEnv key
          when (isNothing existing) $ setEnv key (trim val)
        _ -> pure ()

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

lookupEnvDefault :: String -> String -> IO String
lookupEnvDefault key fallback = fromMaybe fallback <$> lookupEnv key

parseDbBackend :: [String] -> IO DbBackend
parseDbBackend args =
#ifdef POSTGRES
  case (hasSqliteFlag args, findPostgresFlag args) of
    (True, Just _) ->
      error "Cannot use --sqlite and --postgres together"
    (True, Nothing) -> pure SqliteBackend
    (False, spec) -> postgresBackendFromSpec spec
#else
  case findPostgresFlag args of
    Nothing -> pure SqliteBackend
    Just _ ->
      error
        "PostgreSQL support was not compiled in. Rebuild with: cabal build -fpostgres"
#endif

#ifdef POSTGRES
postgresBackendFromSpec :: Maybe (Maybe String) -> IO DbBackend
postgresBackendFromSpec spec = do
  envHost <- lookupEnvDefault "PSQL_HOST" "localhost"
  envPort <- lookupEnvDefault "PSQL_PORT" "5432"
  let (host, portStr) = case spec of
        Nothing -> (envHost, envPort)
        Just (Just s) -> parsePostgresSpec s envHost envPort
        Just Nothing -> (envHost, envPort)
  pure PostgresBackend {pgHost = host, pgPort = read portStr}

parsePostgresSpec :: String -> String -> String -> (String, String)
parsePostgresSpec s envHost envPort =
  case break (== ':') s of
    ("", ':' : p) -> (envHost, p)
    (h, ':' : p) -> (h, p)
    (h, _) -> (h, envPort)

hasSqliteFlag :: [String] -> Bool
hasSqliteFlag =
  any
    ( \arg ->
        arg == "--sqlite" || case stripPrefix "--sqlite=" arg of
          Just _ -> True
          Nothing -> False
    )
#endif

findPostgresFlag :: [String] -> Maybe (Maybe String)
findPostgresFlag = go
  where
    go [] = Nothing
    go ("--postgres" : rest) = Just (specFromRest rest)
    go (arg : rest)
      | Just spec <- stripPrefix "--postgres=" arg = Just (Just spec)
      | otherwise = go rest

specFromRest :: [String] -> Maybe String
specFromRest ("=" : spec : _) = Just spec
specFromRest _ = Nothing

openDb :: DbBackend -> IO DbConn
openDb SqliteBackend = do
  conn <- open dbPath
  initSqliteDb conn
  pure (SqliteConn conn)
#ifdef POSTGRES
openDb PostgresBackend {..} = do
  PostgresConn <$> Postgres.openConnection pgHost pgPort
#endif

closeDb :: DbConn -> IO ()
closeDb (SqliteConn c) = close c
#ifdef POSTGRES
closeDb (PostgresConn c) = Hasql.release c
#endif
