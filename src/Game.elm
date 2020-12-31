module Game exposing (..)


init : Model
init =
    0


type alias Model =
    Int


type Msg
    = Increment


update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            model + 1
