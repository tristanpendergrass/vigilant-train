module NetworkModel exposing (NetworkModel, init)

import Game
import Lamdera exposing (ClientId)


type alias NetworkModel =
    { clientId : ClientId -- client id of this frontend
    , serverSnapshot : Game.Model -- what this frontend thinks the server thinks is this model
    , localMsgs : List Game.Msg -- updates to the model that have been sent to the server but not confirmed
    , localModel : Game.Model -- serverModel with localMsgs applied
    }


init : ClientId -> Game.Model -> NetworkModel
init clientId initialModel =
    { clientId = clientId
    , serverSnapshot = initialModel
    , localMsgs = []
    , localModel = initialModel
    }
