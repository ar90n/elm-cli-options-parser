# Elm CLI Options Parser

## Example

See the `examples` folder for full end-to-end examples, including how to wire
your Elm options parser up through NodeJS so it can receive the command line input.

Take this `git` command:

```console
git log --author=dillon --max-count=5 --stat a410067
```

To parse the above command, we could build an `OptionsParser` as follows (this snippet doesn't include the wiring of the Command-Line options from NodeJS, see the `examples` folder):

```elm
import Cli.Command as Command exposing (Command, with)
import Cli.Option as Option
import Cli.OptionsParser


type GitCommand
    = Init
    | Clone String
    | Log LogOptions


type alias LogOptions =
    { maybeAuthorPattern : Maybe String
    , maybeMaxCount : Maybe Int
    , statisticsMode : Bool
    , maybeRevisionRange : Maybe String
    }


cli : Cli.OptionsParser.Program GitCommand
cli =
    { programName = "git"
    , commands = commands
    , version = "1.2.3"
    }


commands : List (Command GitCommand)
commands =
    [ Command.buildSubCommand "log" LogOptions
        |> with (Option.optionalKeywordArg "author")
        |> with
            (Option.optionalKeywordArg "max-count"
                |> Option.validateMapIfPresent String.toInt
            )
        |> with (Option.flag "stat")
        |> Command.endWith
            (Option.optionalPositionalArg "revision range")
        |> Command.map Log
      -- ... `Command`s for `Init`, `Clone`, etc. here
      -- See `examples` folder
    ]
```

```elm
{-
Now running:
`git log --author=dillon --max-count=5 --stat a410067`
will yield the following output (with wiring as in the `examples` folder):
-}
matchResult : GitCommand
matchResult =
    Log
        { maybeAuthorPattern = Just "dillon"
        , maybeMaxCount = Just 5
        , statisticsMode = True
        , revisionRange = Just "a410067"
        }
```

It will also generate the help text for you, so it's guaranteed to be in sync.
The example code above will generate the following help text:

```console
$ ./git --help
git log [--author <author>] [--max-count <max-count>] [--stat] [<revision range>]
```

Note: the `--help` option is a built-in command, so no need to write a `Command` for that.

## Options Parser Terminology

Here is a diagram to clarify the terminology used by this library. Note that
terms can vary across different standards. For example, posix uses the term
`option` for what this library calls a `keyword argument`. I chose these terms
because I found them to be the most intuitive and unambiguous.

![Options Parser](./terminology.png)

## Some Inspiration for this package

* http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html.
* https://pythonconquerstheuniverse.wordpress.com/2010/07/25/command-line-syntax-some-basic-concepts/
* https://devcenter.heroku.com/articles/cli-style-guide
* http://docopt.org/

## Feedback Wanted On

### Command.withoutRestArgs/withRestArgs

This is needed to enforce the constraint that
this needs to be called once I have the number of arguments that came before it...
so that they can be dropped from the rest args.

### expectFlag is on Command not Option

Right now, I need that because it doesn't change the value of the pipeline... is there a simple way to change that?

### Feedback wanted

Is it confusing to go between Command. and Option.?
