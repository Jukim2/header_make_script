# header_make_script

Script for making header file easily and automatically

Script searches all the c files in the target directory and make a header file.

You can set the starting directory and target directory will be starting directory and  subdirectories

## How to use

**Case 1** : Suppose you want to make ‘myheader.h’ including all the function prototypes in c files below current directory

- Write `ham -n myheader.h`
    1. If you didn’t have ‘myheader.h’ then file will be made with 42 Header, Header Guard, function prototypes
    2. If you did have it, then we will update that file preserving 42 Header, Header Guard, Includes, Define, structs
        
        It means script will change only the part about function prototypes.
        

**Case 2** : If you want to search only for the directory ‘./srcs’, two ways are possible

- Go to ./srcs directory and write `ham -n myheader.h`
- In the root directory just write `ham -n myheader.h -d ./srcs`

Of course at each case, header file will be saved in different directory so you might specify the directory you want your header file to be saved. Like `ham -n ./includes/myheader.h`

**Case 3** : if you want to split function prototypes by file use -s option

- Write `ham -n myheader.h -s` with no option argument. Then prototypes will be seperated in other way.

## Description

### ham [-n File] [-d Directory] [-s Seperation]

- **File** :
    
    Set Name of header file
    
    Default is 'header.h'
    
- **Directory** : 
    
    Set Starting directory
    
    Default is current directory.
    
- **Seperation** :
    
    This option is about choosing way of seperating prototypes
    
    Default is split prototypes by directory.
    
    Adding -s option will split prototypes by file.

## Installation

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Jukim2/header_make_script/main/download.sh)"
```
