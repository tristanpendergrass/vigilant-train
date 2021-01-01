module NetworkModel exposing (NetworkModel, init)

import Game
import Lamdera exposing (ClientId)


type alias NetworkModel gameModel gameMsg =
    { clientId : ClientId -- client id of this frontend
    , serverSnapshot : gameModel -- what this frontend thinks the server thinks is this model
    , localMsgs : List gameMsg -- updates to the model that have been sent to the server but not confirmed
    , localModel : gameModel -- serverModel with localMsgs applied
    }


init : ClientId -> gameModel -> NetworkModel gameModel gameMsg
init clientId initialModel =
    { clientId = clientId
    , serverSnapshot = initialModel
    , localMsgs = []
    , localModel = initialModel
    }
