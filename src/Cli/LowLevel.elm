module Cli.LowLevel exposing (MatchResult(..), helpText, try)

import Cli.Command as Command exposing (Command)
import Cli.Command.MatchResult as MatchResult exposing (MatchResult)
import Cli.Decode
import Set exposing (Set)


type MatchResult msg
    = ValidationErrors (List Cli.Decode.ValidationError)
    | NoMatch (List String)
    | Match msg
    | ShowHelp


intersection : List (Set comparable) -> Set comparable
intersection sets =
    case sets of
        [] ->
            Set.empty

        [ set ] ->
            set

        first :: rest ->
            intersection rest
                |> Set.intersect first


try : List (Command msg) -> List String -> MatchResult msg
try commands argv =
    let
        maybeShowHelpMatch : Maybe (MatchResult msg)
        maybeShowHelpMatch =
            Command.build ShowHelp
                |> Command.expectFlag "help"
                |> Command.toCommand
                |> Command.tryMatchNew (argv |> List.drop 2)
                |> (\matchResult ->
                        case matchResult of
                            MatchResult.NoMatch _ ->
                                Nothing

                            MatchResult.Match _ ->
                                Just ShowHelp
                   )

        matchResults =
            commands
                |> List.map
                    (argv
                        |> List.drop 2
                        |> Command.tryMatchNew
                    )

        commonUnmatchedFlags =
            matchResults
                |> List.map
                    (\matchResult ->
                        case matchResult of
                            MatchResult.NoMatch unknownFlags ->
                                Set.fromList unknownFlags

                            _ ->
                                Set.empty
                    )
                |> intersection
                |> Set.toList
    in
    matchResults
        |> List.map MatchResult.matchResultToMaybe
        |> oneOf
        |> (\maybeResult ->
                case maybeResult of
                    Just result ->
                        case result of
                            Ok msg ->
                                Match msg

                            Err validationErrors ->
                                ValidationErrors validationErrors

                    Nothing ->
                        maybeShowHelpMatch
                            |> Maybe.withDefault
                                (NoMatch commonUnmatchedFlags)
           )


oneOf : List (Maybe a) -> Maybe a
oneOf =
    List.foldl
        (\x acc ->
            if acc /= Nothing then
                acc
            else
                x
        )
        Nothing


helpText : String -> List (Command msg) -> String
helpText programName commands =
    commands
        |> List.map (Command.synopsis programName)
        |> String.join "\n"