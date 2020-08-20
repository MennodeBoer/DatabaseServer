{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE EmptyDataDecls             #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE FlexibleInstances #-}

module Database where


import Data.Aeson                  (ToJSON, FromJSON)
import GHC.Generics                (Generic)
import           Control.Monad.IO.Class  (liftIO)
import Control.Monad.Reader        (ReaderT, asks, liftIO)
import Control.Monad.Logger
import           Database.Persist
import           Database.Persist.Sqlite
import           Database.Persist.TH
import Data.Text
import Servant


import Config

share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
Person 
    name String
    email String
    deriving Show
    
|]

doMigration :: ReaderT SqlBackend IO ()
doMigration = runMigration migrateAll


runDB :: ReaderT SqlBackend IO a -> ReaderT Config Handler a
runDB query = do pool <- asks getPool
                 liftIO $ runSqlPool query pool
