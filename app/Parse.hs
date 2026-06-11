{-# LANGUAGE DeriveTraversable #-}

module Parse where

import           Data.Char (isSpace, toLower)
import           Data.List (isPrefixOf)
import qualified Data.HashMap.Strict as HM
import           Types

trim :: String -> String
trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

normalizeToken :: String -> String
normalizeToken = map toLower . trim

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

verbMap :: HM.HashMap String Verb
verbMap = HM.fromList [(verbKey v, v) | v <- allowedVerbs]

objectMap :: HM.HashMap String ObjectKind
objectMap = HM.fromList [(objectKey o, o) | o <- allowedObjects]

parseVerb :: String -> Maybe Verb
parseVerb s = HM.lookup (normalizeToken s) verbMap

parseObject :: String -> Maybe ObjectKind
parseObject s = HM.lookup (normalizeToken s) objectMap

parseMaybeQuoted :: String -> ParseResult (Maybe String)
parseMaybeQuoted rest
  | null rest = ParseSuccess Nothing
  | "\"" `isPrefixOf` trim rest =
      case parseQuotedText rest of
        Just (content, leftover) | null leftover -> ParseSuccess (Just content)
        _ -> ParseError "malformed quoted text" rest
  | otherwise = ParseSuccess (Just rest)

parseMaybeInt :: String -> ParseResult (Maybe Int)
parseMaybeInt rest
  | null rest = ParseSuccess Nothing
  | otherwise =
      case reads (trim rest) :: [(Int, String)] of
        [(n, "")] -> ParseSuccess (Just n)
        _         -> ParseError "invalid id" rest

parseTwoInts :: String -> ParseResult (Maybe Int, Maybe Int)
parseTwoInts rest =
  let (first, rest') = parseFirstToken rest
  in case parseMaybeInt first of
    ParseError err _ -> ParseError err rest
    ParseSuccess mFirst ->
      case parseMaybeInt rest' of
        ParseError err _ -> ParseError err rest
        ParseSuccess mSecond -> ParseSuccess (mFirst, mSecond)

parseActionLine :: String -> ParseResult ActionInput
parseActionLine input =
  let (verbTok, rest1) = parseFirstToken input
  in case parseVerb verbTok of
    Nothing -> ParseError "unknown action" input
    Just VQuit -> ParseSuccess QuitInput
    Just verb ->
      let (objTok, rest2) = parseFirstToken rest1
      in case parseObject objTok of
        Nothing
          | null (trim objTok) ->
              case verb of
                VList -> ParseSuccess (ListEntityInput Nothing)
                _     -> ParseError "missing object" input
        Nothing -> ParseError "unknown object" input
        Just obj -> case verb of
          VAdd -> parseAddInput obj rest2
          VList -> ParseSuccess (ListEntityInput (Just obj))
          VDelete -> parseDeleteInput obj rest2

parseAddInput :: ObjectKind -> String -> ParseResult ActionInput
parseAddInput OPerson rest = AddPersonInput <$> parseMaybeQuoted rest
parseAddInput OCompany rest = AddCompanyInput <$> parseMaybeQuoted rest
parseAddInput OEvent rest = AddEventInput <$> parseMaybeQuoted rest
parseAddInput OEncounter _ = ParseSuccess AddEncounterInput
parseAddInput OEmployment _ = ParseSuccess AddEmploymentInput
parseAddInput OSponsorship _ = ParseSuccess AddSponsorshipInput

parseDeleteInput :: ObjectKind -> String -> ParseResult ActionInput
parseDeleteInput OEmployment rest =
  case parseTwoInts rest of
    ParseSuccess (a, b) -> ParseSuccess (DeleteEmploymentInput a b)
    ParseError err _    -> ParseError err rest
parseDeleteInput OSponsorship rest =
  case parseTwoInts rest of
    ParseSuccess (a, b) -> ParseSuccess (DeleteSponsorshipInput a b)
    ParseError err _    -> ParseError err rest
parseDeleteInput obj rest = DeleteEntityInput obj <$> parseMaybeInt rest
