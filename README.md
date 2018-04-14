# Long arithmetic implementation for NASM x86_64
This was implemented for a C++ course at ITMO University

`add.asm` was already provided and is unedited

`mul.asm` and `sub.asm` are clean versions of respective functions and do not contain any comments apart from function signatures

`mul-commented.asm` and `sub-commented.asm` are totally the same as `mul.asm` and `sub.asm` respectively, but almost every line in them is commented to make understanding the code easier

To compile any of the files, use `nasm -f elf64 -o <name>.o <name>.asm && ld -o <name> <name>.o`

To run a compiled program, use `./<name>`

Also, a major section of code is just a copy-paste of `add.asm` (as most of the functions are auxiliary), so comments are, for the most part, repeated in the commented files

It must be noted that comments are just as detailed as I needed them to be, so if you do not understand something - it's not my problem :shrug:

No further support will be provided (well, most likely)
