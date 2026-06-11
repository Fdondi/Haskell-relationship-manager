module Main where

import           Control.Monad (when)
import           Complete (completeAction)
import           Db.Schema (openDb)
import           Database.SQLite.Simple (Connection, close)
import           Help (formatErrorSuffix, formatPrompt)
import           Parse (ParseResult (..), parseActionLine)
import           Run (runAction)
import           Types (Action)

main :: IO ()
main = do
  conn <- openDb
  actionLoop conn
  close conn

getCommand :: Connection -> IO (ParseResult Action)
getCommand conn = do
  putStrLn formatPrompt
  input <- getLine
  traverse (completeAction conn) (parseActionLine input)

actionLoop :: Connection -> IO ()
actionLoop conn = do
  maybeAction <- getCommand conn
  case maybeAction of
    ParseSuccess action -> do
      continue <- runAction conn action
      when continue $ actionLoop conn
    ParseError err input -> do
      putStrLn (err ++ ": Invalid command \"" ++ input ++ "\".\n" ++ formatErrorSuffix)
      actionLoop conn
