module Main where

import           Control.Monad (when)
import           Complete (completeAction)
import           Db.Conn (DbConn, closeDb, loadDotEnv, openDb, parseDbBackend)
import           Help (formatErrorSuffix, formatPrompt)
import           Parse (ParseResult (..), parseActionLine)
import           Run (runAction)
import           System.Environment (getArgs)
import           Types (Action)

main :: IO ()
main = do
  args <- getArgs
  _ <- loadDotEnv
  backend <- parseDbBackend args
  conn <- openDb backend
  actionLoop conn
  closeDb conn

getCommand :: DbConn -> IO (ParseResult Action)
getCommand conn = do
  putStrLn formatPrompt
  input <- getLine
  traverse (completeAction conn) (parseActionLine input)

actionLoop :: DbConn -> IO ()
actionLoop conn = do
  maybeAction <- getCommand conn
  case maybeAction of
    ParseSuccess action -> do
      continue <- runAction conn action
      when continue $ actionLoop conn
    ParseError err input -> do
      putStrLn (err ++ ": Invalid command \"" ++ input ++ "\".\n" ++ formatErrorSuffix)
      actionLoop conn
