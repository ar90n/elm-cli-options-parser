module ElmTest exposing (main)

import Cli
import Cli.Command as Command exposing (Command, with)
import Cli.Spec as Spec
import Json.Decode exposing (..)
import Ports
import TypoSuggestion exposing (TypoSuggestion)


type ElmTestCommand
    = Init
    | RunTests RunTestsRecord
    | PrintHelp
    | PrintVersion


type alias RunTestsRecord =
    { maybeFuzz : Maybe Int
    , maybeSeed : Maybe Int
    , maybeCompilerPath : Maybe String
    , maybeDependencies : Maybe String
    , watch : Bool
    , report : Report
    , testFiles : List String
    }



{-
   Usage: elm-test init # Create example tests

   Usage: elm-test TESTFILES # Run TESTFILES, for example tests/**/*.elm

   Usage: elm-test [--fuzz integer] # Run with each fuzz test performing this many iterations

   Usage: elm-test [--version] # Print version string and exit

   Usage: elm-test [--watch] # Run tests on file changes

   Usage: elm-test [--seed integer] # Run with initial fuzzer seed

   Usage: elm-test [--compiler /path/to/compiler] # Run tests

   Usage: elm-test [--add-dependencies path-to-destination-elm-package.json] # Add missing dependencies from current elm-package.json to destination

   Usage: elm-test [--report json, junit, or console (default)] # Print results to stdout in given format

-}


cli : List (Command ElmTestCommand)
cli =
    [ Command.subCommand "init" Init
        |> Command.toCommand
    , Command.build RunTestsRecord
        |> with
            (Spec.optionalKeywordArg "fuzz"
                |> Spec.validateMapMaybe String.toInt
            )
        |> with
            (Spec.optionalKeywordArg "seed"
                |> Spec.validateMapMaybe String.toInt
            )
        |> with (Spec.optionalKeywordArg "compiler")
        |> with (Spec.optionalKeywordArg "add-dependencies")
        |> with (Spec.flag "watch")
        |> with
            (Spec.optionalKeywordArg "report"
                |> Spec.withDefault "console"
                |> Spec.oneOf Console
                    [ Spec.MutuallyExclusiveValue "json" Json
                    , Spec.MutuallyExclusiveValue "junit" Junit
                    , Spec.MutuallyExclusiveValue "console" Console
                    ]
            )
        |> Command.captureRestOperands "TESTFILES"
        |> Command.map RunTests
    , Command.build PrintHelp
        |> Command.expectFlag "help"
        |> Command.toCommand
    , Command.build PrintVersion
        |> Command.expectFlag "version"
        |> Command.toCommand
    ]


type Report
    = Json
    | Junit
    | Console


dummy : Decoder String
dummy =
    -- this is a workaround for an Elm compiler bug
    Json.Decode.string


type alias Flags =
    List String


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        matchResult =
            Cli.try cli flags

        toPrint =
            case matchResult of
                Cli.NoMatch unexpectedOptions ->
                    if unexpectedOptions == [] then
                        "\nNo matching command...\n\nUsage:\n\n"
                            ++ Cli.helpText "elm-test" cli
                    else
                        unexpectedOptions
                            |> List.map (TypoSuggestion.toMessage cli)
                            |> String.join "\n"

                Cli.ValidationErrors validationErrors ->
                    "Validation errors:\n\n"
                        ++ (validationErrors
                                |> List.map
                                    (\{ name, invalidReason, valueAsString } ->
                                        "`"
                                            ++ name
                                            ++ "` failed a validation. "
                                            ++ invalidReason
                                            ++ "\nValue was:\n"
                                            ++ valueAsString
                                    )
                                |> String.join "\n"
                           )

                Cli.Match msg ->
                    case msg of
                        Init ->
                            "Initializing test suite..."

                        RunTests options ->
                            [ "Running the following test files: " ++ toString options.testFiles |> Just
                            , "watch: " ++ toString options.watch |> Just
                            , options.maybeFuzz |> Maybe.map (\fuzz -> "fuzz: " ++ toString fuzz)
                            , options.maybeSeed |> Maybe.map (\seed -> "seed: " ++ toString seed)
                            , options.report |> toString |> Just
                            , options.maybeCompilerPath |> Maybe.map (\compilerPath -> "compiler: " ++ toString compilerPath)
                            , options.maybeDependencies |> Maybe.map (\dependencies -> "dependencies: " ++ toString dependencies)
                            ]
                                |> List.filterMap identity
                                |> String.join "\n"

                        PrintHelp ->
                            Cli.helpText "elm-test" cli

                        PrintVersion ->
                            "You are on version 3.1.4"
    in
    ( (), Ports.print toPrint )


type alias Model =
    ()


type alias Msg =
    ()


main : Program Flags Model Msg
main =
    Platform.programWithFlags
        { init = init
        , update = \msg model -> ( model, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }
