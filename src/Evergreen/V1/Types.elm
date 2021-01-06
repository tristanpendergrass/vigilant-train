module Evergreen.V1.Types exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V1.Game
import Evergreen.V1.NetworkModel
import Lamdera
import Url


type Connection
    = Connected (Evergreen.V1.NetworkModel.NetworkModel Evergreen.V1.Game.Model Evergreen.V1.Game.Msg)
    | NotConnected


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , connection : Connection
    }


type alias BackendModel =Evergreen.V1.Game.Model


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg
    | HandleClick


type ToBackend
    = NoOpToBackend
    | RequestConnection
    | UpdateGame Evergreen.V1.Game.Msg


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend
    | GrantConnection Lamdera.ClientId Evergreen.V1.Game.Model
    | GameUpdated Lamdera.ClientId Evergreen.V1.Game.Msg