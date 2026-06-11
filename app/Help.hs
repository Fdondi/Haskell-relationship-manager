module Help where

import           Types

formatActions :: String
formatActions = unwords (map verbKey allowedVerbs)

formatObjects :: String
formatObjects = unwords (map objectKey allowedObjects)

formatUsage :: String
formatUsage = "Usage: <action> <object> [arguments]  (quit needs no object)"

formatExamples :: String
formatExamples = unlines (map exampleLine examplePairs)
  where
    examplePairs =
      [ (VAdd, OPerson)
      , (VList, OCompany)
      , (VDelete, OEncounter)
      , (VAdd, OEmployment)
      ]
    exampleLine (verb, obj) =
      "  " ++ verbKey verb ++ " " ++ objectKey obj ++ exampleSuffix verb obj

exampleSuffix :: Verb -> ObjectKind -> String
exampleSuffix VDelete OEncounter = " 3"
exampleSuffix VAdd OPerson = " \"Jane Doe\""
exampleSuffix _ _ = ""

formatInstructions :: String
formatInstructions = unwords [ "Actions: ", formatActions, "  | Objects: ", formatObjects ]

formatPrompt :: String
formatPrompt = "\n" ++ formatInstructions ++ "\nEnter command:"

formatErrorSuffix :: String
formatErrorSuffix = formatInstructions
