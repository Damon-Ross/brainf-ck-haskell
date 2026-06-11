import Data.Char
import System.Environment (getArgs)
import System.IO


-- Tape data structure + operations
data Tape = Tape [Int] Int [Int]

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

instance Show Tape where
    show :: Tape -> String
    show (Tape left focus right) =
        show (reverse left) ++ 
        "<" ++ show focus ++ ">"
        ++ show (take 5 right) ++ "..."


showTape :: Int -> Tape -> String
showTape n (Tape left focus right) = 
    show (reverse left) ++ 
    "<" ++ show focus ++ ">"
    ++ show (take n right) ++ "..."


data Instruction = Single Char | Block [Instruction]
    deriving (Show)

type Program = [Instruction]

-- Parsing logic

parse :: String -> Either String Program
parse input = case parseLoop input of
    Left error -> Left error
    Right (program, "") -> Right program
    Right (_, ']':_) -> Left "Unmatched closing bracket ']'"
    Right (_, _) -> Left "Parsing error"


parseLoop:: String -> Either String (Program, String) -- Returns parsed intructions and remaining unparsed string. 
parseLoop [] = Right ([], "")

parseLoop (c:chars)
    -- parsing instruction char
    | c `elem` "+-><.," = do
        (rest, leftovers) <- parseLoop chars
        return (Single c : rest, leftovers)
    
    -- parsing [, starting new block
    | c == '[' = do
        (inBlock, afterBlock) <- parseLoop chars
        case afterBlock of
            (']':afterString) -> do
                (rest, leftovers) <- parseLoop afterString
                return (Block inBlock : rest, leftovers)
            _ -> Left "Unmatched opening bracket '['"

    
    -- parsing ], ending block
    | c == ']'=
        Right ([], c:chars)
    
    | otherwise = parseLoop chars

-- Evaluation logic

eval :: Program -> Tape -> IO Tape
eval [] tape = return tape

eval (instruction:rest) tape = do
    newTape <- evalInst instruction tape
    eval rest newTape

evalInst :: Instruction -> Tape -> IO Tape

evalInst (Single '+') tape = return $! (increment tape)
evalInst (Single '-') tape = return $! (decrement tape)
evalInst (Single '<') tape = return $! (moveLeft tape)
evalInst (Single '>') tape = return $! (moveRight tape)

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
            case parse code of
                Left error -> do
                    putStrLn "----- Parse Error -----"
                    putStrLn error

                Right program -> do
                    _ <- eval program emptyTape
                    return ()

            return ()
        _ -> do
            putStrLn "Usage: project.hs <filename.bf>"
            putStrLn "Within ghci: :main <filename.bf>"


