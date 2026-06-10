{-# LANGUAGE OverloadedStrings #-}

import           Control.Monad (when)
import           Data.Char (isSpace, toLower)
import           Data.List (isPrefixOf)
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

-- all lowercase! input will be normalized to lowercase
actionKey :: Action -> String
actionKey Add = "add"
actionKey List = "list"
actionKey DeleteID = "deleteid"
actionKey Quit = "quit"

actionMap :: HM.HashMap String Action
actionMap = HM.fromList [(actionKey a, a) | a <- allowedActions]

trim :: String -> String
trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

normalizeAction :: String -> String
normalizeAction = map toLower . trim

parseAction :: String -> Maybe Action
parseAction s = HM.lookup (normalizeAction s) actionMap

parseFirstToken :: String -> (String, String)
parseFirstToken s =
  case break (==' ') (trim s) of
    (word, rest) -> (word, trim rest)

parseQuotedText :: String -> Maybe (String, String)
parseQuotedText s =
  case dropWhile isSpace s of
    '"' : rest ->
      case break (=='"') rest of
        (content, '"' : after) -> Just (content, trim after)
        _                      -> Nothing
    _ -> Nothing

-- Omitted: prompt the user for this field; Given: use the inline value
data OptArg a = Omitted | Given a deriving (Show)

promptOptArg :: OptArg String -> String -> IO String
promptOptArg (Given x) _ = pure x
promptOptArg Omitted prompt = do
  putStrLn prompt
  getLine

data ParseResult a = ParseSuccess a | ParseError String deriving (Show)

instance Functor ParseResult where
  fmap f (ParseSuccess a) = ParseSuccess (f a)
  fmap _ (ParseError e)   = ParseError e

parseAddRest :: String -> ParseResult (OptArg String)
parseAddRest rest
  | null rest = ParseSuccess Omitted
  | "\"" `isPrefixOf` trim rest =
      case parseQuotedText rest of
        Just (name, leftover) | null leftover -> ParseSuccess (Given name)
        _ -> ParseError "malformed quoted name"
  | otherwise = ParseSuccess (Given rest)

parseDeleteIdRest :: String -> ParseResult (OptArg String)
parseDeleteIdRest rest
  | null rest = ParseSuccess Omitted
  | otherwise =
      case reads (trim rest) :: [(Int, String)] of
        [(_, "")] -> ParseSuccess (Given (trim rest))
        _         -> ParseError "invalid id"

data ParsedCommand
  = ParsedAdd (OptArg String)
  | ParsedList
  | ParsedDeleteID (OptArg String)
  | ParsedQuit
  deriving (Show)

parseCommandLine :: String -> ParseResult ParsedCommand
parseCommandLine input =
  let (actionTok, rest) = parseFirstToken input
  in case parseAction actionTok of
    Nothing -> ParseError "unknown action"
    Just action -> case action of
      Add      -> ParsedAdd <$> parseAddRest rest
      List     -> ParseSuccess ParsedList
      DeleteID -> ParsedDeleteID <$> parseDeleteIdRest rest
      Quit     -> ParseSuccess ParsedQuit

formatAllowedActions :: String
formatAllowedActions = unwords (map actionKey allowedActions)

runAction :: Connection -> ParsedCommand -> IO Bool
runAction conn (ParsedAdd nameArg) = do
  name <- promptOptArg nameArg "Enter name: "
  putStrLn "Enter notes: "
  notes <- getLine
  execute conn "INSERT INTO people (name, notes) VALUES (?,?)" (T.pack name, T.pack notes)
  putStrLn "Person added"
  pure True
runAction conn ParsedList = do
  putStrLn "Current people: "
  r <- query_ conn "SELECT * from people" :: IO [PersonField]
  mapM_ print r
  pure True
runAction conn (ParsedDeleteID idArg) = do
  idStr <- promptOptArg idArg "Enter ID to delete: "
  let id_ = read idStr :: Int
  execute conn "DELETE FROM people WHERE id = ?" (Only id_)
  putStrLn ("Person with ID " ++ show id_ ++ " deleted")
  pure True
runAction _conn ParsedQuit = do
  putStrLn "Quitting..."
  pure False

actionLoop :: Connection -> IO ()
actionLoop conn = do
  putStrLn ("Enter action (allowed: " ++ formatAllowedActions ++ "): ")
  actionStr <- getLine
  case parseCommandLine actionStr of
    ParseSuccess cmd -> do
      continue <- runAction conn cmd
      when continue $ actionLoop conn
    ParseError _err -> do
      putStrLn ("Invalid action \"" ++ actionStr ++ "\". Allowed: " ++ formatAllowedActions)
      actionLoop conn

main :: IO ()
main = do
  conn <- open "realtionships.db"
  execute_ conn "CREATE TABLE IF NOT EXISTS people (id INTEGER PRIMARY KEY, name TEXT, notes TEXT)"
  actionLoop conn
  close conn