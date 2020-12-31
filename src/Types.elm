module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Game
import Lamdera exposing (ClientId)
import Url exposing (Url)


type Connection
    = Connected ClientId Game.Model
    | NotConnected


type alias FrontendModel =
    { key : Key
    , connection : Connection
    , localMsgs : List Game.Msg
    , serverSnapshot : Game.Model
    }


type alias BackendModel =
    Game.Model


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
    | HandleClick


type ToBackend
    = NoOpToBackend
    | RequestConnection
    | UpdateGame Game.Msg


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend
    | GrantConnection ClientId Game.Model
    | GameUpdated ClientId Game.Msg
