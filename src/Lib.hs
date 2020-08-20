{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DataKinds       #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators   #-}
module Lib
    (app
    ) where

import Data.Aeson
import Data.Aeson.TH
import Network.Wai
import Network.Wai.Handler.Warp
import Control.Monad.Reader        (ReaderT, runReaderT, asks, liftIO)
import GHC.Generics
import Database.Persist
import Database.Persist.Sqlite
import Database.Persist.TH
import Servant

import Config
import Database
    
data User = User
    { name :: String
    , email :: String
    } deriving (Eq, Show, Generic)

instance ToJSON User
instance FromJSON User

userToPerson :: Person -> User
userToPerson Person{..} = User { name = personName, email = personEmail }


type API = "users" :> (Get '[JSON] [User]
                      :<|> ReqBody '[JSON] User :> PostCreated '[JSON] String
                      :<|> Capture "name" String :> Get '[JSON] User)
           
type AppM = ReaderT Config Handler


api :: Proxy API
api = Proxy

app :: Config -> Application
app cfg = serve api (readerServer cfg)

readerServer :: Config -> Server API
readerServer cfg = hoistServer api (readerTtoHandler cfg) serverReaderT

readerTtoHandler :: Config -> AppM a -> Handler a
readerTtoHandler cfg = \x -> runReaderT x cfg

serverReaderT :: ServerT API AppM
serverReaderT = getUsersServer :<|> postUserServer :<|> getUserServer

getUsersServer :: AppM [User]
getUsersServer = do people <- runDB $ selectList [] []
                    let users = map (\(Entity _ y) -> userToPerson y) people
                    return users

postUserServer :: User -> AppM String
postUserServer usr = do usrId <- runDB $ insert $ Person (name usr) (email usr)
                        return ("added " ++ show usr ++ " with key " ++ show (fromSqlKey usrId))


getUserServer :: String -> AppM User
getUserServer str = do people <- runDB $ selectList [PersonName ==. str] [LimitTo 1]
                       let users = map (\(Entity _ y) -> userToPerson y) people
                       case users of
                         [] -> throwError err404
                         (x:xs) -> return x
