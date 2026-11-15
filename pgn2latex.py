"""
Convert the main line of a PGN game to a LaTeX chess animation.
"""
import argparse
import sys
from pathlib import Path

import chess.pgn


LATEX_SPECIAL_CHARS = {
    "\\": r"\textbackslash{}",
    "{": r"\{",
    "}": r"\}",
    "$": r"\$",
    "&": r"\&",
    "#": r"\#",
    "%": r"\%",
    "_": r"\_",
    "^": r"\textasciicircum{}",
    "~": r"\textasciitilde{}",
}


def latex_escape(text: str) -> str:
    return "".join(LATEX_SPECIAL_CHARS.get(char, char) for char in text)


def positive_integer(value: str) -> int:
    try:
        number = int(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError("must be a positive integer") from error
    if number < 1:
        raise argparse.ArgumentTypeError("must be a positive integer")
    return number


def convert_pgn_to_latex(
    input_path: Path, fps: int, orientation: str | None
) -> str:
    with input_path.open(encoding="utf-8") as pgn_file:
        game = chess.pgn.read_game(pgn_file)

    if game is None:
        raise ValueError(f"No PGN game found in {input_path}")
    if game.errors:
        details = "; ".join(str(error) for error in game.errors)
        raise ValueError(f"Could not parse PGN game: {details}")

    if orientation is None:
        orientation = game.headers.get("Orientation", "white").lower()
    if orientation not in {"white", "black"}:
        raise ValueError(
            f"Unsupported board orientation {orientation!r}; use 'white' or 'black'"
        )

    board = game.board()
    positions = [board.fen()]
    for move in game.mainline_moves():
        board.push(move)
        positions.append(board.fen())

    white = latex_escape(game.headers.get("White", "White"))
    black = latex_escape(game.headers.get("Black", "Black"))
    title = f"{white} vs. {black}"
    orientation_option = ",inverse=true" if orientation == "black" else ""

    frames = [
        rf"\chessboard[setfen={{{fen}}}{orientation_option},marginrightwidth=2em]"
        for fen in positions
    ]
    animation = r"\newframe".join(frames)
    document = rf"""\documentclass{{article}}
\usepackage{{chessboard}}
\usepackage{{animate}}

\begin{{document}}
\pagestyle{{empty}}


\begin{{center}}
\textbf{{{title}}}

\begin{{animateinline}}[autoplay,loop,controls]{{{fps}}}
{animation}
\end{{animateinline}}
\end{{center}}


\end{{document}}
"""
    return document


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert a PGN game's main line into an animated LaTeX chessboard."
    )
    parser.add_argument("input", type=Path, help="input PGN file")
    output_group = parser.add_mutually_exclusive_group()
    output_group.add_argument(
        "-o",
        "--output",
        type=Path,
        help="output .tex file (default: input file with a .tex extension)",
    )
    output_group.add_argument(
        "-s",
        "--stdout",
        action="store_true",
        help="write the generated LaTeX document to standard output",
    )
    parser.add_argument(
        "--fps",
        type=positive_integer,
        default=1,
        help="animation speed in frames per second (default: 1)",
    )
    parser.add_argument(
        "--orientation",
        choices=("white", "black"),
        help="board orientation (default: PGN Orientation header, or white)",
    )
    args = parser.parse_args()
    try:
        document = convert_pgn_to_latex(args.input, args.fps, args.orientation)
        if args.stdout:
            sys.stdout.write(document)
        else:
            output_path = args.output or args.input.with_suffix(".tex")
            output_path.write_text(document, encoding="utf-8")
    except (OSError, ValueError) as error:
        print(f"pgn2latex: {error}", file=sys.stderr)
        return 1

    if not args.stdout:
        print(f"Wrote {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
