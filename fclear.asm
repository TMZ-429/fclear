%define SYS_EXIT  60
%define SYS_READ  0
%define SYS_WRITE 1

%define STDIN     0
%define STDOUT    1

%define F_CLOSE   3 
%define F_OPEN    2
%define F_LSEEK   8

%define TRUNCATION_ROUTINES 2 ; How many times to overwrite the entire file

section .bss
    fsize     resq 1   ; A quadword can hold a number equal to 2^64 - 1, which is far more bytes than a Linux file system can contain
    zero      resb 1   ; It's called zero, but it flips between 1 and 0 and is what is used to flip bytes in the file
    fname     resb 256 ; max file name length in Linux is 255, the extra byte is there to make room for the full name + enter key

section .data                            ;
    prompt_fname db  'Enter file name >_';
    pfname_len   equ $ - prompt_fname    ; 

section .text
    global _start        ;
_start:
    mov rax, 0           ;
    mov [zero], rax      ;

    mov rax, SYS_WRITE   ; Ask for file name
    mov rdi, STDOUT      ;
    mov rsi, prompt_fname;
    mov rdx, pfname_len  ;
    syscall              ;

    mov rax, SYS_READ    ; Get file name from input
    mov rdi, STDIN       ;
    mov rsi, fname       ;
    mov rdx, 256         ;
    syscall              ;

remove_endline:          ; Remove the newline character at the end
    cmp byte[rsi], 0xA   ; check if the current character is the newline character
    je remover           ; if it is, jump to the remover section and remove it, while moving on to the next process
    inc rsi              ; if it isn't, move on to the next character
    cmp byte[rsi], 0     ; this is just in case the input somehow doesn't have a newline character (if we're somehow at the end of the string)
    jne remove_endline   ;
    jmp post_remover     ;
remover:
    mov byte[rsi], 0     ;
post_remover:
    mov rax, F_OPEN      ; Open file
    mov rdi, fname       ;
    mov rsi, 2           ; Read & Write
    mov rdx, 777         ;
    syscall              ;

    mov rdi, rax         ; Every subsequent syscall is going to require the file pointer being in rdi, so I just move it in here and never touch the register to save a bunch of time complexity

    mov rax, F_LSEEK     ; Get file size
    mov rsi, 0           ; Offset (0 because we want to start at the very start)
    mov rdx, 2           ; Seek_END
    syscall              ;

    mov [fsize], rax     ; fsize is the file size

    mov rcx, TRUNCATION_ROUTINES  ;
main_loop:
    push rcx                      ;
    mov rax, F_LSEEK              ; Go to the start of the file to re-truncate it
    mov rsi, 0                    ; Offset 0 (start at the start)
    mov rdx, 0                    ;
    syscall                       ;

    call flip_truncator           ; Flip between truncating entire file to 1s & 0s
    mov rcx, [fsize]              ; This is the looper for how many times we truncate the current byte then move on to truncate the next
file_truncation_routine:          ; 
    push rcx                      ; Iterate through every byte in the file & truncate it
    mov  rax, SYS_WRITE           ;
    mov  rsi, zero                ;
    mov  rdx, 1                   ;
    syscall                       ;
    pop  rcx                      ;
    loop file_truncation_routine  ;
    pop  rcx                      ;
loop main_loop
exit:
    mov rax, F_CLOSE    ; Close the file (rdi is still the file pointer)
    syscall             ;

    mov rax, SYS_EXIT   ;
    xor rdi, rdi        ;
    syscall             ;

flip_truncator:
    mov rax, [zero] ;
    xor rax, 1      ; Theoretically you could go from 0-255, idk if going 0-1 is fine.
    mov [zero], rax ;
    ret             ;
