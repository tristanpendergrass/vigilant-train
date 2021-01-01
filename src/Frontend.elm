module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Game
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Lamdera
import List.Extra
import NetworkModel exposing (NetworkModel)
import Types exposing (..)
import Url


type alias Model =
    FrontendModel


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \m -> Sub.none
        , view = view
        }


init : Url.Url -> Nav.Key -> ( Model, Cmd FrontendMsg )
init url key =
    ( { key = key
      , connection = NotConnected
      }
    , Lamdera.sendToBackend RequestConnection
    )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Cmd.batch [ Nav.pushUrl model.key (Url.toString url) ]
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChanged url ->
            ( model, Cmd.none )

        NoOpFrontendMsg ->
            ( model, Cmd.none )

        HandleClick ->
            case model.connection of
                NotConnected ->
                    ( model, Cmd.none )

                Connected networkModel ->
                    let
                        localMsgs : List Game.Msg
                        localMsgs =
                            Game.Increment :: networkModel.localMsgs

                        localModel : Game.Model
                        localModel =
                            Game.update Game.Increment networkModel.localModel

                        newNetworkModel : NetworkModel Game.Model Game.Msg
                        newNetworkModel =
                            { networkModel
                                | localModel = localModel
                                , localMsgs = localMsgs
                            }
                    in
                    ( { model | connection = Connected newNetworkModel }
                    , Lamdera.sendToBackend (UpdateGame Game.Increment)
                    )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none )

        GrantConnection clientId gameModel ->
            let
                networkModel : NetworkModel Game.Model Game.Msg
                networkModel =
                    NetworkModel.init clientId gameModel
            in
            ( { model | connection = Connected networkModel }, Cmd.none )

        GameUpdated updaterId gameMsg ->
            case model.connection of
                NotConnected ->
                    ( model, Cmd.none )

                Connected networkModel ->
                    if networkModel.clientId == updaterId then
                        let
                            newNetworkModel : NetworkModel Game.Model Game.Msg
                            newNetworkModel =
                                { networkModel
                                    | serverSnapshot = Game.update gameMsg networkModel.serverSnapshot
                                    , localMsgs = List.Extra.remove gameMsg networkModel.localMsgs
                                }
                        in
                        ( { model | connection = Connected newNetworkModel }
                        , Cmd.none
                        )

                    else
                        let
                            newServerModel : Game.Model
                            newServerModel =
                                Game.update gameMsg networkModel.serverSnapshot

                            newLocalModel : Game.Model
                            newLocalModel =
                                networkModel.localMsgs
                                    |> List.foldl Game.update newServerModel

                            newNetworkModel : NetworkModel Game.Model Game.Msg
                            newNetworkModel =
                                { networkModel
                                    | serverSnapshot = newServerModel
                                    , localModel = newLocalModel
                                }
                        in
                        ( { model | connection = Connected newNetworkModel }
                        , Cmd.none
                        )


view model =
    { title = "Community Clicker"
    , body =
        [ div [ style "text-align" "center", style "padding-top" "40px" ]
            [ img [ src "https://lamdera.app/lamdera-logo-black.png", width 150 ] []
            , div
                [ style "font-family" "sans-serif"
                , style "padding-top" "40px"
                ]
                [ case model.connection of
                    NotConnected ->
                        text "Establishing connection"

                    Connected networkModel ->
                        div []
                            [ div [] [ text <| String.fromInt networkModel.localModel ]
                            , button [ onClick HandleClick ] [ text "Click me" ]
                            , hr [] []

                            -- TODO: move localMsgs and serverShapshot to be in connection
                            , div [] [ text <| "ServerSnapshot: " ++ String.fromInt networkModel.serverSnapshot ]
                            , div [] [ text "localMsgs:" ]
                            , ul []
                                (List.map
                                    (\localMsg ->
                                        case localMsg of
                                            Game.Increment ->
                                                li [] [ text "Increment" ]
                                    )
                                    networkModel.localMsgs
                                )
                            ]
                ]
            ]
        ]
    }
