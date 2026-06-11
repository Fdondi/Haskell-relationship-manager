{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module Db.Postgres.Links
  ( addEmployment
  , addSponsorship
  , listEmployment
  , listSponsorship
  , employmentExists
  , sponsorshipExists
  , deleteEmployment
  , deleteSponsorship
  , printEmployment
  , printSponsorship
  ) where

import           Data.Functor.Contravariant ((>$<))
import           Db.Postgres.Query
import           Db.Postgres.Schema
import           Rel8
import           Types

import qualified Hasql.Connection as Hasql

addEmployment :: Hasql.Connection -> Int -> Int -> IO Bool
addEmployment conn personId companyId = do
  runStatement_ conn $
    insert $
      Insert
        { into = employmentSchema
        , rows =
            values
              [ Employment (lit (fromIntegral personId)) (lit (fromIntegral companyId))
              ]
        , returning = NoReturning
        , onConflict = DoNothing
        }
  putStrLn "Employment link added (or already existed)"
  pure True

addSponsorship :: Hasql.Connection -> Int -> Int -> IO Bool
addSponsorship conn eventId companyId = do
  runStatement_ conn $
    insert $
      Insert
        { into = sponsorshipSchema
        , rows =
            values
              [ Sponsorship (lit (fromIntegral eventId)) (lit (fromIntegral companyId))
              ]
        , returning = NoReturning
        , onConflict = DoNothing
        }
  putStrLn "Sponsorship link added (or already existed)"
  pure True

listEmployment :: Hasql.Connection -> IO [EmploymentRow]
listEmployment conn = do
  rows <-
    runQuery conn $
      select $
        orderBy (mconcat [ejPersonId >$< asc, ejCompanyId >$< asc]) $
          do
            emp <- each employmentSchema
            p <- each personSchema
            c <- each companySchema
            where_ $
              personId p ==. employmentPersonId emp
                &&. companyId c ==. employmentCompanyId emp
            return $
              EmploymentJoin
                (employmentPersonId emp)
                (personName p)
                (employmentCompanyId emp)
                (companyName c)
  pure
    [ EmploymentRow
        (fromIntegral (ejPersonId r))
        (ejPersonName r)
        (fromIntegral (ejCompanyId r))
        (ejCompanyName r)
    | r <- rows
    ]

listSponsorship :: Hasql.Connection -> IO [SponsorshipRow]
listSponsorship conn = do
  rows <-
    runQuery conn $
      select $
        orderBy (mconcat [sjEventId >$< asc, sjCompanyId >$< asc]) $
          do
            sp <- each sponsorshipSchema
            e <- each eventSchema
            c <- each companySchema
            where_ $
              eventId e ==. sponsorshipEventId sp
                &&. companyId c ==. sponsorshipCompanyId sp
            return $
              SponsorshipJoin
                (sponsorshipEventId sp)
                (eventLocation e)
                (sponsorshipCompanyId sp)
                (companyName c)
  pure
    [ SponsorshipRow
        (fromIntegral (sjEventId r))
        (sjEventLocation r)
        (fromIntegral (sjCompanyId r))
        (sjCompanyName r)
    | r <- rows
    ]

employmentExists :: Hasql.Connection -> Int -> Int -> IO Bool
employmentExists conn personId companyId = do
  rows <-
    runQuery conn $
      select $
        do
          emp <- each employmentSchema
          where_ $
            employmentPersonId emp ==. lit (fromIntegral personId)
              &&. employmentCompanyId emp ==. lit (fromIntegral companyId)
          return emp
  pure (not (Prelude.null rows))

sponsorshipExists :: Hasql.Connection -> Int -> Int -> IO Bool
sponsorshipExists conn eventId companyId = do
  rows <-
    runQuery conn $
      select $
        do
          sp <- each sponsorshipSchema
          where_ $
            sponsorshipEventId sp ==. lit (fromIntegral eventId)
              &&. sponsorshipCompanyId sp ==. lit (fromIntegral companyId)
          return sp
  pure (not (Prelude.null rows))

deleteEmployment :: Hasql.Connection -> Int -> Int -> IO Bool
deleteEmployment conn personId companyId = do
  existed <- employmentExists conn personId companyId
  runStatement_ conn $
    delete $
      Delete
        { from = employmentSchema
        , using = pure ()
        , deleteWhere =
            \_ emp ->
              employmentPersonId emp ==. lit (fromIntegral personId)
                &&. employmentCompanyId emp ==. lit (fromIntegral companyId)
        , returning = NoReturning
        }
  if existed
    then putStrLn "Employment link deleted" >> pure True
    else putStrLn "Employment link not found" >> pure True

deleteSponsorship :: Hasql.Connection -> Int -> Int -> IO Bool
deleteSponsorship conn eventId companyId = do
  existed <- sponsorshipExists conn eventId companyId
  runStatement_ conn $
    delete $
      Delete
        { from = sponsorshipSchema
        , using = pure ()
        , deleteWhere =
            \_ sp ->
              sponsorshipEventId sp ==. lit (fromIntegral eventId)
                &&. sponsorshipCompanyId sp ==. lit (fromIntegral companyId)
        , returning = NoReturning
        }
  if existed
    then putStrLn "Sponsorship link deleted" >> pure True
    else putStrLn "Sponsorship link not found" >> pure True

printEmployment :: Hasql.Connection -> IO ()
printEmployment conn = do
  putStrLn "Employment:"
  mapM_ print =<< listEmployment conn

printSponsorship :: Hasql.Connection -> IO ()
printSponsorship conn = do
  putStrLn "Sponsorship:"
  mapM_ print =<< listSponsorship conn
