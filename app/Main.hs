{-# LANGUAGE OverloadedStrings #-}

import           Control.Monad (when)
import qualified Data.HashMap.Strict as HM
import qualified Data.Text as T
import           Database.SQLite.Simple

type PersonName = T.Text
type PersonNotes = T.Text
-- type PersonCompanyID = Int

data PersonField = PersonField Int PersonName PersonNotes deriving (Show)

instance FromRow PersonField where
  fromRow = PersonField <$> field <*> field <*> field

instance ToRow PersonField where
  toRow (PersonField id_ name notes) = toRow (id_, name, notes)


{-
type CompanyName = T.Text
type CompanyNotes = T.Text

data CompanyField  = CompanyField Int CompanyName CompanyNotes deriving (Show)


type EventName = T.Text
type EventNotes = T.Text
type CompanySponsor
-}

data Action = Add | List | DeleteID | Quit deriving (Show, Eq, Enum, Bounded)

allowedActions :: [Action]
allowedActions = [minBound .. maxBound]

actionKey :: Action -> String
actionKey Add = "add"
actionKey List = "list"
actionKey DeleteID = "deleteID"
actionKey Quit = "quit"

actionMap :: HM.HashMap String Action
actionMap = HM.fromList [(actionKey a, a) | a <- allowedActions]

parseAction :: String -> Maybe Action
parseAction s = HM.lookup s actionMap

formatAllowedActions :: String
formatAllowedActions = unwords (map actionKey allowedActions)

runAction :: Connection -> Action -> IO Bool
runAction conn Add = do
  putStrLn "Enter name: "
  name <- getLine
  putStrLn "Enter notes: "
  notes <- getLine
  execute conn "INSERT INTO people (name, notes) VALUES (?,?)" (T.pack name, T.pack notes)
  putStrLn "Person added"
  pure True
runAction conn List = do
  putStrLn "Current people: "
  r <- query_ conn "SELECT * from people" :: IO [PersonField]
  mapM_ print r
  pure True
runAction conn DeleteID = do
  putStrLn "Enter ID to delete: "
  removed_id <- getLine
  execute conn "DELETE FROM people WHERE id = ?" (Only (read removed_id :: Int))
  putStrLn ("Person with ID " ++ removed_id ++ " deleted")
  pure True
runAction _conn Quit = do
  putStrLn "Quitting..."
  pure False

actionLoop :: Connection -> IO ()
actionLoop conn = do
  putStrLn ("Enter action (allowed: " ++ formatAllowedActions ++ "): ")
  actionStr <- getLine
  case parseAction actionStr of
    Just action -> do
      continue <- runAction conn action
      when continue $ actionLoop conn
    Nothing -> do
      putStrLn ("Invalid action. Allowed: " ++ formatAllowedActions)
      actionLoop conn

main :: IO ()
main = do
  conn <- open "realtionships.db"
  execute_ conn "CREATE TABLE IF NOT EXISTS people (id INTEGER PRIMARY KEY, name TEXT, notes TEXT)"
  actionLoop conn
  close conn