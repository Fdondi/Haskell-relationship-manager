{-# LANGUAGE OverloadedStrings #-}

-- import           Control.Applicative
import qualified Data.Text as T
import           Database.SQLite.Simple
import System.Exit (exitSuccess)
-- import           Database.SQLite.Simple.FromRow

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

actionLoop :: Connection -> IO ()
actionLoop conn = do
  putStrLn "Enter action: "
  action <- getLine
  case action of
    "add" -> do
      putStrLn ("Enter name: " :: String)
      name <- getLine
      putStrLn ("Enter notes: " :: String)
      notes <- getLine
      execute conn "INSERT INTO people (name, notes) VALUES (?,?)" (T.pack name, T.pack notes)
      putStrLn "Person added"
    "list" -> do
      putStrLn "Current people: "
      r <- query_ conn "SELECT * from people" :: IO [PersonField]
      mapM_ print r
    "deleteID" -> do
      putStrLn ("Enter ID to delete: " :: String)
      removed_id <- getLine
      execute conn "DELETE FROM people WHERE id = ?" (Only (read removed_id :: Int))
      putStrLn ("Person with ID " ++ removed_id ++ " deleted")
    "quit" -> do
      close conn
      putStrLn "Quitting..."
      exitSuccess
    _ -> putStrLn ("Invalid action" :: String)
  actionLoop conn

main :: IO ()
main = do
  conn <- open "realtionships.db"
  execute_ conn "CREATE TABLE IF NOT EXISTS people (id INTEGER PRIMARY KEY, name TEXT, notes TEXT)"
  actionLoop conn
  close conn