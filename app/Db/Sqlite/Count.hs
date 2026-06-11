{-# LANGUAGE OverloadedStrings #-}

module Db.Sqlite.Count where

import           Database.SQLite.Simple

newtype CountRow = CountRow Int deriving (Show)

instance FromRow CountRow where
  fromRow = CountRow <$> field
