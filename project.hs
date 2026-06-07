import Data.Char
import System.Environment (getArgs)
import System.IO

-- Tape data structure + operations
data Tape = Tape [Int] Int [Int]
    deriving (Show)

emptyTape :: Tape
emptyTape = Tape [] 0 (repeat 0)

increment :: Tape -> Tape
increment (Tape left focus right) = Tape left (abs ((focus + 1) `mod` 256)) right

decrement :: Tape -> Tape
decrement (Tape left focus right) = Tape left (abs ((focus - 1) `mod` 256)) right

moveRight :: Tape -> Tape
moveRight (Tape left focus (r:right)) = Tape (focus : left) r right

moveLeft :: Tape -> Tape
moveLeft (Tape (l:left) focus right) = Tape left l (focus : right)
moveLeft (Tape [] _ _) = error "Attempted to move left of tape bound"

setFocus :: Int -> Tape -> Tape
setFocus n (Tape left _ right) = Tape left (abs (n `mod` 256)) right

getFocus :: Tape -> Int
getFocus (Tape _ focus _) = focus

showTape :: Int -> Tape -> String
showTape n (Tape left focus right) = 
    show (reverse left) ++ 
    "<" ++ show focus ++ ">"
    ++ show (take n right) ++ "..."


data Instruction = Single Char | Block [Instruction]
    deriving (Show)

type Program = [Instruction]

-- Parsing logic

parse :: String -> Program
parse input =
    prog
    where (prog, leftovers) = parseLoop input -- By this point the parseLoop would simply produce [] for leftovers

parseLoop:: String -> (Program, String) -- Returns parsed intructions and remaining unparsed string. 
parseLoop [] = ([], "")

parseLoop (c:chars)
    -- parsing instruction char
    | c `elem` "+-><.," =
        let (rest, leftovers) = parseLoop chars
        in (Single c : rest, leftovers)
    
    -- parsing [, starting new block
    | c == '[' =
        let (inBlock, afterBlock) = parseLoop chars
            (rest, leftovers) = parseLoop afterBlock
        in (Block inBlock : rest, leftovers)
    
    -- parsing ], ending block
    | c == ']'=
        ([], chars)
    
    | otherwise = parseLoop chars

-- Evaluation logic

eval :: Program -> Tape -> IO Tape
eval [] tape = return tape

eval (instruction:rest) tape = do
    newTape <- evalInst instruction tape
    eval rest newTape

evalInst :: Instruction -> Tape -> IO Tape

evalInst (Single '+') tape = return (increment tape)
evalInst (Single '-') tape = return (decrement tape)
evalInst (Single '<') tape = return (moveLeft tape)
evalInst (Single '>') tape = return (moveRight tape)

evalInst (Single '.') tape = do
    let currentNumber = getFocus tape
    putChar (chr currentNumber)
    return tape

evalInst (Single ',') tape = do
    char <- getChar
    let value = ord char
    return (setFocus value tape)

evalInst (Block loop) tape = do
    if getFocus tape == 0
        then return tape
    else do
        tapeAfter <- eval loop tape
        evalInst (Block loop) tapeAfter

main :: IO ()
main = do
    args <- getArgs

    case args of
        [file] -> do
            code <- readFile file
            let program = parse code

            _ <- eval program emptyTape

            return ()
        _ -> putStrLn "Usage: project.hs <filename.bf>"


