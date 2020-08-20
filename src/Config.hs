{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE EmptyDataDecls             #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE TypeFamilies               #-}

module Config where


import Network.Wai.Middleware.RequestLogger (logStdoutDev, logStdout)
import Network.Wai                          (Middleware)
import           Control.Monad.IO.Class  (liftIO)
import           Database.Persist
import           Database.Persist.Sqlite
import           Database.Persist.TH
import Control.Monad.Logger                 (runNoLoggingT, runStdoutLoggingT)
import Data.Text
import Data.Pool


data Config = Config 
    { getPool :: ConnectionPool
    , getEnv  :: Environment
    }

data Environment = 
    Development
  | Test
  | Production
  deriving (Eq, Show, Read)


setLogger :: Environment -> Middleware
setLogger Test = id
setLogger Development = logStdoutDev
setLogger Production = logStdout

makePool :: Environment -> IO (Pool SqlBackend)
makePool Test = runNoLoggingT $ createSqlitePool (connStr Test) (envPool Test)
makePool e = runStdoutLoggingT  $ createSqlitePool (connStr e) (envPool e)

envPool :: Environment -> Int
envPool Test = 1
envPool Development = 1
envPool Production = 8

connStr :: Environment -> Text
connStr _ = "test.db"
