module Evergreen.V1.NetworkModel exposing (..)

import Lamdera


type alias NetworkModel gameModel gameMsg = 
    { clientId : Lamdera.ClientId
    , serverSnapshot : gameModel
    , localMsgs : (List gameMsg)
    , localModel : gameModel
    }