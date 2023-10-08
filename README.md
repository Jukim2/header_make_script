# 🐧header_make_script

Script for making header file easily and automatically.

It searches all the c files in the target directory and make a header file.

⚠️ files end with 'bonus.c' will be excluded by default. You can change this by commenting out the second line of script.
  It is in the home directory.
  
⚠️ Use Tab to indent between return type and function name(Norminette)

## Installation

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Jukim2/header_make_script/main/download.sh)"
```

## Description

### ham [-n File] [-d Directory] [-s Seperation] [-e Exclude] [-h Help]

- **-n File** :
    
    Set Name of header file
    
    Default is 'header.h'
    
- **-d Directory** : 
    
    Set Starting directory
    
    Default is current directory.
    
- **-s Seperation** :
    
    This option is about choosing way of seperating prototypes
    
    Default is split prototypes by directory.
    
    Adding -s option will split prototypes by file.
    
- **-e Exclude** :
    
    set path that would be excluded during the search. (mostly would be libft)
    
    Or you can open script file and set default path that would be excluded by just changing the variable on the fourth line of script
    

## How to use

**Case 1 : Basic Use** : Make ‘myheader.h’ including all the function prototypes in c files below current directory

- `ham -n myheader.h`
    1. If you didn’t have ‘myheader.h’ then file will be made with 42 Header, Header Guard, function prototypes
    2. If you did have it, then we will update that file preserving 42 Header, Header Guard, Includes, Define, structs
        
        It means script will change only the part about function prototypes.
        

**Case 2** : Want C files under certain Directory like './srcs'

- write `ham -n myheader.h -d ./srcs`

**Case 3** : Want to split function prototypes by file

- Write `ham -n myheader.h -s` with no option argument. Then prototypes will be seperated in other way.


