module Main exposing (..)

import Html as H
import Html.Attributes as HA
import Svg exposing (..)
import Svg.Attributes exposing (..)


main =
    H.beginnerProgram
        { model = model
        , view = view
        , update = update
        }


type alias Boxplot =
    { realMin : Int
    , min : Int
    , firstQuartile : Int
    , median : Int
    , thirdQuartile : Int
    , max : Int
    , realMax : Int
    , outliers : List Int
    }


type alias Model =
    { boxplots : List Boxplot }


model =
    { boxplots =
        [ { realMin = 0
          , min = 20
          , firstQuartile = 200
          , median = 240
          , thirdQuartile = 300
          , max = 500
          , realMax = 760
          , outliers = [ 0, 520, 680, 760 ]
          }
        , { realMin = 0
          , min = 20
          , firstQuartile = 200
          , median = 240
          , thirdQuartile = 300
          , max = 500
          , realMax = 760
          , outliers = [ 0, 520, 680, 760 ]
          }
        ]
    }


update : msg -> Model -> Model
update msg model =
    model


view model =
    H.div []
        [ H.h1 []
            [ H.text "Boxplot"
            , svg
                [ version "1.1"
                , x "0"
                , y "0"
                , viewBox "0 0 800 800"
                , HA.style
                    [ ( "border", "solid thin black" )
                    , ( "margin", "10pt" )
                    ]
                , fill "#fff"
                , stroke "#000"
                , strokeWidth "1"
                ]
                [ (g [ transform "translate(140, 20)" ] (boxplot (List.head model.boxplots)))
                , line [ y1 "20", x1 "60", y2 "780", x2 "60", stroke "#000" ] []
                , line [ y1 "20", x1 "55", y2 "20", x2 "65", stroke "#000" ] []
                , line [ y1 "780", x1 "55", y2 "780", x2 "65", stroke "#000" ] []
                ]
            ]
        ]


boxplot : Maybe Boxplot -> List (Svg msg)
boxplot data =
    case data of
        Nothing ->
            [ text "NA" ]

        Just data ->
            List.concat
                [ [ line
                        [ x1 "0"
                        , y1 (data.min |> flipY |> toString)
                        , x2 "20"
                        , y2 (data.min |> flipY |> toString)
                        ]
                        []
                  , line
                        [ x1 "10"
                        , y1 (data.min |> flipY |> toString)
                        , x2 "10"
                        , y2 (data.firstQuartile |> flipY |> toString)
                        ]
                        []
                  , rect
                        [ x "0"
                        , y (data.thirdQuartile |> flipY |> toString)
                        , height ((data.thirdQuartile - data.firstQuartile) |> toString)
                        , width "20"
                        ]
                        []
                  , line
                        [ x1 "0"
                        , y1 (data.median |> flipY |> toString)
                        , x2 "20"
                        , y2 (data.median |> flipY |> toString)
                        ]
                        []
                  , line
                        [ x1 "10"
                        , y1 (data.thirdQuartile |> flipY |> toString)
                        , x2 "10"
                        , y2 (data.max |> flipY |> toString)
                        ]
                        []
                  , line
                        [ x1 "0"
                        , y1 (data.max |> flipY |> toString)
                        , x2 "20"
                        , y2 (data.max |> flipY |> toString)
                        ]
                        []
                  ]
                , (List.map
                    (\n ->
                        circle
                            [ cx "10"
                            , cy (n |> flipY |> toString)
                            , r "2"
                            , strokeWidth "0.5"
                            ]
                            []
                    )
                    data.outliers
                  )
                ]


flipY y =
    760 - y
