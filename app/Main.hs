{-# LANGUAGE DeriveTraversable #-}
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

data Action
  = Add PersonName PersonNotes
  | List
  | DeleteID Int
  | Quit
  deriving (Show)

data Verb = VAdd | VList | VDeleteID | VQuit deriving (Show, Eq, Enum, Bounded)

allowedVerbs :: [Verb]
allowedVerbs = [minBound .. maxBound]

-- all lowercase! input will be normalized to lowercase
verbKey :: Verb -> String
verbKey VAdd = "add"
verbKey VList = "list"
verbKey VDeleteID = "deleteid"
verbKey VQuit = "quit"

verbMap :: HM.HashMap String Verb
verbMap = HM.fromList [(verbKey v, v) | v <- allowedVerbs]

trim :: String -> String
trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

normalizeVerb :: String -> String
normalizeVerb = map toLower . trim

parseVerb :: String -> Maybe Verb
parseVerb s = HM.lookup (normalizeVerb s) verbMap

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

data ParseResult a = ParseSuccess a | ParseError String String deriving (Show, Functor, Foldable, Traversable)

data ActionInput
  = AddInput (Maybe String)
  | ListInput
  | DeleteIDInput (Maybe Int)
  | QuitInput
  deriving (Show)

parseAddRest :: String -> ParseResult (Maybe String)
parseAddRest rest
  | null rest = ParseSuccess Nothing
  | "\"" `isPrefixOf` trim rest =
      case parseQuotedText rest of
        Just (name, leftover) | null leftover -> ParseSuccess (Just name)
        _ -> ParseError "malformed quoted name" rest
  | otherwise = ParseSuccess (Just rest)

parseDeleteIdRest :: String -> ParseResult (Maybe Int)
parseDeleteIdRest rest
  | null rest = ParseSuccess Nothing
  | otherwise =
      case reads (trim rest) :: [(Int, String)] of
        [(n, "")] -> ParseSuccess (Just n)
        _         -> ParseError "invalid id" rest

parseActionLine :: String -> ParseResult ActionInput
parseActionLine input =
  let (verbTok, rest) = parseFirstToken input
  in case parseVerb verbTok of
    Nothing -> ParseError "unknown action" input
    Just verb -> case verb of
      VAdd      -> AddInput <$> parseAddRest rest
      VList     -> ParseSuccess ListInput
      VDeleteID -> DeleteIDInput <$> parseDeleteIdRest rest
      VQuit     -> ParseSuccess QuitInput

getIfMissing :: Read a => Maybe a -> String -> IO a
getIfMissing (Just a) _ = pure a
getIfMissing Nothing prompt = do
  putStrLn prompt
  read <$> getLine

-- in case we need extra fields that weren't supplied in the first line, request them here
completeAction :: ActionInput -> IO Action
completeAction (AddInput mName) = do
  nameStr <- getIfMissing mName "Enter name: "
  putStrLn "Enter notes: "
  Add (T.pack nameStr) . T.pack <$> getLine
completeAction ListInput = pure List
completeAction (DeleteIDInput mId) = do
  id_ <- getIfMissing mId "Enter ID to delete: "
  pure (DeleteID id_)
completeAction QuitInput = pure Quit

getCommand :: IO (ParseResult Action)
getCommand = do
  putStrLn ("Enter action (allowed: " ++ formatAllowedVerbs ++ "): ")
  input <- getLine
  traverse completeAction (parseActionLine input)

formatAllowedVerbs :: String
formatAllowedVerbs = unwords (map verbKey allowedVerbs)

runAction :: Connection -> Action -> IO Bool
runAction conn (Add name notes) = do
  execute conn "INSERT INTO people (name, notes) VALUES (?,?)" (name, notes)
  putStrLn "Person added"
  pure True
runAction conn List = do
  putStrLn "Current people: "
  r <- query_ conn "SELECT * from people" :: IO [PersonField]
  mapM_ print r
  pure True
runAction conn (DeleteID id_) = do
  execute conn "DELETE FROM people WHERE id = ?" (Only id_)
  putStrLn ("Person with ID " ++ show id_ ++ " deleted")
  pure True
runAction _conn Quit = do
  putStrLn "Quitting..."
  pure False

actionLoop :: Connection -> IO ()
actionLoop conn = do
  maybeAction <- getCommand
  case maybeAction of
    ParseSuccess action -> do
      continue <- runAction conn action
      when continue $ actionLoop conn
    ParseError _err input -> do
      putStrLn (_err ++ ": Invalid action \"" ++ input ++ "\". Allowed: " ++ formatAllowedVerbs)
      actionLoop conn

main :: IO ()
main = do
  conn <- open "realtionships.db"
  execute_ conn "CREATE TABLE IF NOT EXISTS people (id INTEGER PRIMARY KEY, name TEXT, notes TEXT)"
  actionLoop conn
  close conn