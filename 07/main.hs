import Data.List
import Debug.Trace

data Command = 
    Ls [String] 
    | Cd String
    deriving (Show)

data FileItem =
    File Int String
    | Directory String [FileItem]
    deriving (Show)

parseInput :: String -> [Command]
parseInput x = case parseLs x of
                 Just (y, z) -> y : parseInput z
                 Nothing -> case parseCd x of 
                              Just (y, z) -> y : parseInput z
                              Nothing -> []

parseLs :: String -> Maybe (Command, String)
parseLs x
  | "$ ls" `isPrefixOf` x = let (y, z) = span (/= '$') (drop 5 x) in 
                                Just (Ls (splitOn '\n' y), z)
  | otherwise = Nothing

parseCd :: String -> Maybe (Command, String)
parseCd x
  | "$ cd" `isPrefixOf` x = let (y, z) = span (/= '\n') (drop 5 x) in 
                                Just (Cd y, tail z)
  | otherwise = Nothing

splitOn :: Char -> String -> [String]
splitOn _ [] = []
splitOn delim target = 
    let (x, xs) = span (/= delim) target in 
        x : splitOn delim (if null xs then [] else tail xs)

eval :: [Command] -> FileItem -> (FileItem, [Command])
eval [] cd = (cd, [])
eval ((Cd dir):cs) cd
    | dir == ".." = (cd, cs)
    | otherwise = let (x, y) = eval cs (findFile cd dir) in eval y (addToDir cd x)
eval ((Ls dirs):cs) (Directory n _) = eval cs (Directory n (toDirs dirs))
eval _ _ = (File 0 "", [])

addToDir :: FileItem -> FileItem -> FileItem
addToDir (Directory n []) f = f
addToDir (Directory n dirs) f = Directory n (map (replaceFile f) dirs)
addToDir x _ = x

replaceFile :: FileItem -> FileItem -> FileItem
replaceFile (Directory a b) (Directory c d)
    | a == c = Directory a b 
    | otherwise = Directory c d
replaceFile (File a b) (File c d)
    | b == d = File a b
    | otherwise = File c d
replaceFile x _ = x

findFile :: FileItem -> String -> FileItem
findFile (Directory _ files) file = case find f files of
                                        Just x -> x
                                        Nothing -> Directory file []
                                    where f (Directory n _) = n == file
                                          f (File _ n) = n == file
findFile x _ = x

toDirs :: [String] -> [FileItem]
toDirs = map (\x -> if "dir" `isPrefixOf` x then Directory (drop 4 x) [] else let [size, name] = splitOn ' ' x in File (read size) name) . filter (/= "")

main = print (eval (parseInput "$ cd /\n$ ls\ndir a\n14848514 b.txt\n8504156 c.dat\ndir d\n$ cd a\n$ ls\ndir e\n29116 f\n2557 g\n62596 h.lst\n$ cd e\n$ ls\n584 i\n$ cd ..\n$ cd ..\n$ cd d\n$ ls\n4060174 j\n8033020 d.log\n5626152 d.ext\n7214296 k\n\n") (Directory "/" []))
