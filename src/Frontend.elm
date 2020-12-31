module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Game
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Lamdera
import List.Extra
import Types exposing (..)
import Url


type alias Model =
    FrontendModel


type alias NetworkModel =
    { localMsgs : List FrontendMsg
    , serverState : Model
    }


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
      , localMsgs = []
      , serverSnapshot = Game.init
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

                Connected clientId gameModel ->
                    ( { model
                        | connection = Connected clientId (Game.update Game.Increment gameModel)
                        , localMsgs = Game.Increment :: model.localMsgs
                      }
                    , Lamdera.sendToBackend (UpdateGame Game.Increment)
                    )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none )

        GrantConnection clientId gameModel ->
            ( { model | connection = Connected clientId gameModel, serverSnapshot = gameModel }, Cmd.none )

        GameUpdated updaterId gameMsg ->
            case model.connection of
                NotConnected ->
                    ( model, Cmd.none )

                Connected clientId gameModel ->
                    if clientId == updaterId then
                        ( { model
                            | localMsgs = List.Extra.remove gameMsg model.localMsgs -- localMsgs.remove(gameMsg)
                            , serverSnapshot = Game.update gameMsg model.serverSnapshot
                          }
                        , Cmd.none
                        )

                    else
                        let
                            newServerSnapshot : Game.Model
                            newServerSnapshot =
                                Game.update gameMsg (Debug.log "gameModel" model.serverSnapshot)

                            newGameModel : Game.Model
                            newGameModel =
                                Debug.log "model.localMsgs" model.localMsgs
                                    |> List.foldl Game.update (Debug.log "newServerSnapshot" newServerSnapshot)
                        in
                        ( { model
                            | connection = Connected clientId (Debug.log "newGameModel" newGameModel)
                            , serverSnapshot = newServerSnapshot
                          }
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

                    Connected _ counter ->
                        div []
                            [ div [] [ text <| String.fromInt counter ]
                            , button [ onClick HandleClick ] [ text "Click me" ]
                            , hr [] []

                            -- TODO: move localMsgs and serverShapshot to be in connection
                            , div [] [ text <| "ServerSnapshot: " ++ String.fromInt model.serverSnapshot ]
                            , div [] [ text "localMsgs:" ]
                            , ul []
                                (List.map
                                    (\localMsg ->
                                        case localMsg of
                                            Game.Increment ->
                                                li [] [ text "Increment" ]
                                    )
                                    model.localMsgs
                                )
                            ]
                ]
            ]
        ]
    }
