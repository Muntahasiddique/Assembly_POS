INCLUDE Irvine32.inc
INCLUDELIB kernel32.lib

.data
; Product Management Variables
maxProducts = 100
priceString BYTE 16 DUP(0)
tempReal8 REAL8 ?
hundred REAL8 100.0

; File handling variables
productsFilename BYTE "products.dat",0
cardFilename    BYTE "cardinfo.dat",0
fileHandle HANDLE ?
bytesRead DWORD ?
writeCount DWORD ?

; Product Management Prompts
promptName     BYTE 0dh, 0ah, "                                    >> Enter *Product Name*: ", 0
promptPrice    BYTE 0dh, 0ah, "                                    >> Enter *Product Price*: ", 0
promptStock    BYTE 0dh, 0ah, "                                    >> Enter *Stock Quantity*: ", 0
fullMsg        BYTE 0dh,0ah,"                                    **** Product List is FULL! ****", 0dh,0ah, 0
emptyMsg       BYTE 0dh,0ah,"                                    **** No Products Found ****", 0dh,0ah, 0
deletePrompt   BYTE 0dh, 0ah, "                                    >> Enter *Product ID* to delete: ", 0
notFoundMsg    BYTE 0dh,0ah,"                                      ** Product Not Found! **", 0dh,0ah, 0
deletedMsg     BYTE 0dh,0ah,"                                      ** Product Deleted Successfully **", 0dh,0ah, 0
productAddedMsg BYTE 0dh,0ah,"                                      ** Product Added Successfully **", 0dh,0ah, 0
invalidChoiceMsg BYTE 0dh,0ah,"                                    **** Invalid Choice! Please enter 1-5 ****", 0dh,0ah, 0
pauseMsg       BYTE 0dh,0ah,"                                Press any key to return to menu...", 0
emptyInputMsg  BYTE 0dh,0ah,"** Input cannot be empty or invalid! **", 0dh,0ah, 0
saveSuccessMsg BYTE 0dh,0ah,"                                      ** Products Saved Successfully **", 0dh,0ah, 0
loadSuccessMsg BYTE 0dh,0ah,"                                      ** Products Loaded Successfully **", 0dh,0ah, 0
fileErrorMsg   BYTE 0dh,0ah,"                                      ** Error accessing file! **", 0dh,0ah, 0

nameBuffer BYTE 50 DUP(0)
priceBuffer BYTE 20 DUP(0)
stockBuffer BYTE 20 DUP(0)

invalidPriceMsg BYTE 0dh,0ah,"** Invalid Price! Please enter a valid positive number. **",0dh,0ah,0
invalidStockMsg BYTE 0dh,0ah,"** Invalid Stock! Please enter a valid positive integer. **",0dh,0ah,0

; Card Payment Prompts
promptCardNum   BYTE 0dh, 0ah, ">> Enter Card Number (16 digits): ", 0
promptCardPIN   BYTE 0dh, 0ah, ">> Enter Card PIN (4 digits): ", 0
invalidCardMsg  BYTE 0dh,0ah,"[!] Invalid Card Number. Must be exactly 16 digits (0-9).", 0
invalidPINMsg   BYTE 0dh,0ah,"[!] Invalid PIN. Must be exactly 4 digits (0-9).", 0
cardSavedMsg    BYTE 0dh,0ah,"** Card Info Saved Successfully **", 0dh,0ah, 0
paymentSuccessMsg BYTE 0dh,0ah,"** Payment Processed Successfully **", 0dh,0ah, 0
totalAmountMsg  BYTE 0dh,0ah,">> Total Amount: $",0

; Menu Prompts
menuPrompt BYTE 0dh,0ah
           BYTE "                                                   **********************************", 0dh,0ah
           BYTE "                                                   *        POS Invoice System      *", 0dh,0ah
           BYTE "                                                   **********************************", 0dh,0ah
           BYTE "                                                   * 1. Create Product              *", 0dh,0ah
           BYTE "                                                   * 2. List Products               *", 0dh,0ah
           BYTE "                                                   * 3. Delete Product              *", 0dh,0ah
           BYTE "                                                   * 4. Save/Load Products          *", 0dh,0ah
           BYTE "                                                   * 5. Process Payment             *", 0dh,0ah
           BYTE "                                                   * 6. Exit                        *", 0dh,0ah
           BYTE "                                                   **********************************", 0dh,0ah
           BYTE "                                                       >> Enter your *Choice*: ", 0

listHeader BYTE "                        ================== Product List ==================", 0
labelID      BYTE 0dh,0ah, "                        -> Product ID    : ", 0
labelName    BYTE "                        -> Product Name  : ", 0
labelPrice   BYTE "                        -> Product Price : $", 0
labelStock   BYTE "                        -> Stock Quantity: ", 0
productSeparator BYTE 0dh,0ah, "                        ------------------------------------------", 0dh,0ah, 0

fileMenuPrompt BYTE 0dh,0ah
               BYTE "                                                   **********************************", 0dh,0ah
               BYTE "                                                   *        File Operations         *", 0dh,0ah
               BYTE "                                                   **********************************", 0dh,0ah
               BYTE "                                                   * 1. Save Products to File      *", 0dh,0ah
               BYTE "                                                   * 2. Load Products from File    *", 0dh,0ah
               BYTE "                                                   * 3. Return to Main Menu        *", 0dh,0ah
               BYTE "                                                   **********************************", 0dh,0ah
               BYTE "                                                       >> Enter your *Choice*: ", 0

productCount DWORD 0

; Card Payment Variables
cardNumBuffer   BYTE 17 DUP(0)    ; 16 digits + null terminator
pinBuffer       BYTE 5 DUP(0)     ; 4 digits + null terminator
pinHash         DWORD ?

; Product Structure
Product STRUCT
    id DWORD ?
    name BYTE 50 DUP(0)
    price REAL8 ?
    stock DWORD ?
Product ENDS

productArray Product maxProducts DUP(<0>)

; Console Handling
.data?
hConsole HANDLE ?
colorAttr WORD ?

.code
main PROC
    INVOKE GetStdHandle, -11
    mov hConsole, eax

    mov colorAttr, 0F5h
    INVOKE SetConsoleTextAttribute, hConsole, colorAttr

    call Clrscr

    ; Load products at startup
    call LoadProductsFromFile

menu:
    call Clrscr
    mov edx, OFFSET menuPrompt
    call WriteString
    call ReadInt

    cmp eax, 1
    je create
    cmp eax, 2
    je list
    cmp eax, 3
    je delete
    cmp eax, 4
    je fileOps
    cmp eax, 5
    je processPayment
    cmp eax, 6
    je quit
    
    ; Invalid menu choice
    mov eax, hConsole
    mov cx, 04h
    INVOKE SetConsoleTextAttribute, eax, cx
    
    mov edx, OFFSET invalidChoiceMsg
    call WriteString
    
    mov cx, 0F5h
    INVOKE SetConsoleTextAttribute, eax, cx
    
    mov edx, OFFSET pauseMsg
    call WriteString
    call ReadChar
    jmp menu

create:
    call Clrscr
    call CreateProduct
    jmp menu

list:
    call Clrscr
    call ListProducts
    jmp menu

delete:
    call Clrscr
    call DeleteProduct
    jmp menu

fileOps:
    call Clrscr
    call FileOperations
    jmp menu

processPayment:
    call Clrscr
    call ProcessPayment
    jmp menu

quit:
    ; Save products before exiting
    call SaveProductsToFile
    
    mov eax, hConsole
    mov cx, 07h
    INVOKE SetConsoleTextAttribute, eax, cx

    INVOKE ExitProcess, 0
main ENDP

; File operations menu
FileOperations PROC
fileMenu:
    call Clrscr
    mov edx, OFFSET fileMenuPrompt
    call WriteString
    call ReadInt

    cmp eax, 1
    je saveProducts
    cmp eax, 2
    je loadProducts
    cmp eax, 3
    je returnToMain
    
    ; Invalid menu choice
    mov eax, hConsole
    mov cx, 04h
    INVOKE SetConsoleTextAttribute, eax, cx
    
    mov edx, OFFSET invalidChoiceMsg
    call WriteString
    
    mov cx, 0F5h
    INVOKE SetConsoleTextAttribute, eax, cx
    
    mov edx, OFFSET pauseMsg
    call WriteString
    call ReadChar
    jmp fileMenu

saveProducts:
    call Clrscr
    call SaveProductsToFile
    
    mov edx, OFFSET pauseMsg
    call WriteString
    call ReadChar
    jmp fileMenu

loadProducts:
    call Clrscr
    call LoadProductsFromFile
    
    mov edx, OFFSET pauseMsg
    call WriteString
    call ReadChar
    jmp fileMenu

returnToMain:
    ret
FileOperations ENDP

; Save products to file
SaveProductsToFile PROC
    ; Create or overwrite the file
    INVOKE CreateFile,
        ADDR productsFilename,
        GENERIC_WRITE,
        DO_NOT_SHARE,
        NULL,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        0
    
    mov fileHandle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je fileError

    ; First write the product count
    INVOKE WriteFile,
        fileHandle,
        ADDR productCount,
        SIZEOF productCount,
        ADDR writeCount,
        NULL
    
    ; Then write the product array
    mov eax, productCount
    imul eax, SIZEOF Product
    INVOKE WriteFile,
        fileHandle,
        ADDR productArray,
        eax,
        ADDR writeCount,
        NULL
    
    INVOKE CloseHandle, fileHandle

    mov edx, OFFSET saveSuccessMsg
    call WriteString
    ret

fileError:
    mov edx, OFFSET fileErrorMsg
    call WriteString
    ret
SaveProductsToFile ENDP

; Load products from file
LoadProductsFromFile PROC
    ; Open the file for reading
    INVOKE CreateFile,
        ADDR productsFilename,
        GENERIC_READ,
        DO_NOT_SHARE,
        NULL,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        0
    
    mov fileHandle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je fileError

    ; First read the product count
    INVOKE ReadFile,
        fileHandle,
        ADDR productCount,
        SIZEOF productCount,
        ADDR bytesRead,
        NULL
    
    ; Then read the product array
    mov eax, productCount
    imul eax, SIZEOF Product
    INVOKE ReadFile,
        fileHandle,
        ADDR productArray,
        eax,
        ADDR bytesRead,
        NULL
    
    INVOKE CloseHandle, fileHandle

    mov edx, OFFSET loadSuccessMsg
    call WriteString
    ret

fileError:
    ; If file doesn't exist, just initialize with empty array
    mov productCount, 0
    ret
LoadProductsFromFile ENDP

CreateProduct PROC
    mov eax, productCount
    cmp eax, maxProducts
    jge noSpace

    mov esi, productCount
    imul esi, SIZEOF Product
    lea edi, productArray
    add edi, esi

    mov eax, productCount
    inc eax
    mov [edi], eax

    ; Get product name with validation
getName:
    mov edx, OFFSET promptName
    call WriteString
    mov edx, edi
    add edx, 4              ; edx points to product name field
    mov ecx, 50
    call ReadString
    cmp eax, 0              ; if nothing entered
    je nameInvalid

    ; Validate name: only alphabetic characters or space
    mov esi, edi
    add esi, 4              ; esi points to name buffer

validateNameLoop:
    mov al, [esi]
    cmp al, 0
    je nameValid            ; end of string, all valid

    ; Check if alphabet or space
    cmp al, 'A'
    jl nameInvalid
    cmp al, 'Z'
    jle nextChar

    cmp al, 'a'
    jl notAlpha
    cmp al, 'z'
    jle nextChar

notAlpha:
    cmp al, ' '
    jne nameInvalid

nextChar:
    inc esi
    jmp validateNameLoop

nameInvalid:
    mov eax, hConsole
    mov cx, 04h
    INVOKE SetConsoleTextAttribute, eax, cx

    mov edx, OFFSET emptyInputMsg
    call WriteString

    mov cx, 0F5h
    INVOKE SetConsoleTextAttribute, eax, cx
    jmp getName

nameValid:
    jmp getPrice

getPrice:
    mov edx, OFFSET promptPrice
    call WriteString
    call ReadFloat

    ; Check if price is valid (positive)
    fldz
    fcomip st(0), st(1)     ; Compare entered price with 0
    jbe priceValid          ; If price >= 0, jump

    ; Invalid price - show error
    mov eax, hConsole
    mov cx, 04h
    INVOKE SetConsoleTextAttribute, eax, cx

    mov edx, OFFSET invalidPriceMsg
    call WriteString

    mov cx, 0F5h
    INVOKE SetConsoleTextAttribute, eax, cx

    fstp st(0)              ; Clear FPU stack
    jmp getPrice

priceValid:
    fstp QWORD PTR [edi + 54]

    ; Get stock quantity with validation
getStock:
    mov edx, OFFSET promptStock
    call WriteString
    call ReadInt

    ; Check if stock is valid (positive)
    cmp eax, 0
    jg stockValid

    ; Invalid stock - show error
    mov eax, hConsole
    mov cx, 04h
    INVOKE SetConsoleTextAttribute, eax, cx

    mov edx, OFFSET invalidStockMsg
    call WriteString

    mov cx, 0F5h
    INVOKE SetConsoleTextAttribute, eax, cx
    jmp getStock

stockValid:
    mov [edi + 62], eax

    inc productCount

    mov eax, hConsole
    mov cx, 0F5h
    INVOKE SetConsoleTextAttribute, eax, cx

    mov edx, OFFSET productAddedMsg
    call WriteString

    mov edx, OFFSET pauseMsg
    call WriteString
    call ReadChar
    ret

noSpace:
    mov eax, hConsole
    mov cx, 04h
    INVOKE SetConsoleTextAttribute, eax, cx

    mov edx, OFFSET fullMsg
    call WriteString

    mov cx, 0F5h
    INVOKE SetConsoleTextAttribute, eax, cx
    
    mov edx, OFFSET pauseMsg
    call WriteString
    call ReadChar
    ret
CreateProduct ENDP

ListProducts PROC
    call Clrscr
    cmp productCount, 0
    je noProducts

    call Crlf
    mov edx, OFFSET listHeader
    call WriteString
    call Crlf

    mov ecx, productCount
    xor esi, esi

nextProduct:
    mov eax, esi
    imul eax, SIZEOF Product
    lea edi, productArray
    add edi, eax

    ; Display Product ID
    mov edx, OFFSET labelID
    call WriteString
    mov eax, [edi]
    call WriteDec
    call Crlf

    ; Display Product Name
    mov edx, OFFSET labelName
    call WriteString
    mov edx, edi
    add edx, 4
    call WriteString
    call Crlf

    ; Display Product Price with proper formatting
    mov edx, OFFSET labelPrice
    call WriteString
    
    ; Load price and store it
    fld QWORD PTR [edi + 54]    ; Load price
    fst tempReal8               ; Store in memory
    
    ; Extract integer part (dollars)
    fld tempReal8
    frndint                     ; Round to integer
    fistp DWORD PTR tempReal8   ; Store as integer
    mov eax, DWORD PTR tempReal8
    call WriteDec               ; Display dollars
    
    ; Display decimal point
    mov al, '.'
    call WriteChar
    
    ; Calculate cents (fractional part * 100)
    fld tempReal8
    fild DWORD PTR tempReal8    ; Load integer part
    fsubp st(1), st(0)         ; Get fractional part
    fmul hundred               ; Multiply by 100
    frndint                    ; Round cents
    fistp DWORD PTR tempReal8  ; Store cents
    
    ; Display cents (always 2 digits)
    mov eax, DWORD PTR tempReal8
    cmp eax, 10
    jae display_cents
    push eax
    mov al, '0'
    call WriteChar
    pop eax
    
display_cents:
    call WriteDec
    
    call Crlf

    ; Display Stock Quantity
    mov edx, OFFSET labelStock
    call WriteString
    mov eax, [edi + 62]
    call WriteDec
    call Crlf

    mov edx, OFFSET productSeparator
    call WriteString

    inc esi
    dec ecx
    jnz nextProduct

    call Crlf
    mov edx, OFFSET pauseMsg
    call WriteString
    call ReadChar
    ret

noProducts:
    mov edx, OFFSET emptyMsg
    call WriteString
    call Crlf
    mov edx, OFFSET pauseMsg
    call WriteString
    call ReadChar
    ret
ListProducts ENDP

DeleteProduct PROC
    call Clrscr
    call ListProducts
    cmp productCount, 0
    je noProductsToDelete

    mov edx, OFFSET deletePrompt
    call WriteString
    call ReadInt
    mov ebx, eax

    mov ecx, productCount
    xor esi, esi

searchLoop:
    mov eax, esi
    imul eax, SIZEOF Product
    lea edi, productArray
    add edi, eax

    mov eax, [edi]
    cmp eax, ebx
    je found

    inc esi
    loop searchLoop

    mov eax, hConsole
    mov cx, 04h
    INVOKE SetConsoleTextAttribute, eax, cx

    mov edx, OFFSET notFoundMsg
    call WriteString

    mov cx, 0F5h
    INVOKE SetConsoleTextAttribute, eax, cx
    
    mov edx, OFFSET pauseMsg
    call WriteString
    call ReadChar
    ret

found:
    mov edx, productCount
    dec edx
    mov productCount, edx

    mov eax, esi
    inc eax
    imul eax, SIZEOF Product
    lea esi, productArray
    add esi, eax

    lea edi, productArray
    mov ecx, esi
    sub ecx, edi
    add edi, ecx

    mov ecx, (maxProducts * SIZEOF Product)
    sub ecx, eax
    rep movsb

    mov eax, hConsole
    mov cx, 0F5h
    INVOKE SetConsoleTextAttribute, eax, cx

    mov edx, OFFSET deletedMsg
    call WriteString
    
    mov edx, OFFSET pauseMsg
    call WriteString
    call ReadChar
    ret
    
noProductsToDelete:
    ret
DeleteProduct ENDP

; Payment Processing Functions
ProcessPayment PROC
    call Clrscr
    call ListProducts
    cmp productCount, 0
    je noProductsForPayment
    
    ; Calculate total amount (sum all product prices)
    fldz    ; Initialize total to 0
    mov ecx, productCount
    xor esi, esi
    
calculateTotal:
    mov eax, esi
    imul eax, SIZEOF Product
    lea edi, productArray
    add edi, eax
    
    fld QWORD PTR [edi + 54]    ; Load product price
    faddp st(1), st(0)          ; Add to total
    
    inc esi
    loop calculateTotal
    
    ; Display total amount
    call Crlf
    mov edx, OFFSET totalAmountMsg
    call WriteString
    
    ; Format and display the total price
    fst tempReal8               ; Store in memory
    
    ; Extract integer part (dollars)
    fld tempReal8
    frndint                     ; Round to integer
    fistp DWORD PTR tempReal8   ; Store as integer
    mov eax, DWORD PTR tempReal8
    call WriteDec               ; Display dollars
    
    ; Display decimal point
    mov al, '.'
    call WriteChar
    
    ; Calculate cents (fractional part * 100)
    fld tempReal8
    fild DWORD PTR tempReal8    ; Load integer part
    fsubp st(1), st(0)         ; Get fractional part
    fmul hundred               ; Multiply by 100
    frndint                    ; Round cents
    fistp DWORD PTR tempReal8  ; Store cents
    
    ; Display cents (always 2 digits)
    mov eax, DWORD PTR tempReal8
    cmp eax, 10
    jae display_total_cents
    push eax
    mov al, '0'
    call WriteChar
    pop eax
    
display_total_cents:
    call WriteDec
    call Crlf
    
    ; Process payment
    call EnterCardDetails
    
    ; After successful payment
    mov edx, OFFSET paymentSuccessMsg
    call WriteString
    mov edx, OFFSET pauseMsg
    call WriteString
    call ReadChar
    ret
    
noProductsForPayment:
    ret
ProcessPayment ENDP

EnterCardDetails PROC
    ; Clear buffers
    mov ecx, 16
    mov edi, OFFSET cardNumBuffer
    xor al, al
    rep stosb
    
    mov ecx, 4
    mov edi, OFFSET pinBuffer
    xor al, al
    rep stosb

getCardNumber:
    mov edx, OFFSET promptCardNum
    call WriteString

    mov edx, OFFSET cardNumBuffer
    mov ecx, 17          ; max 16 digits + null terminator
    call ReadString      ; eax = number of chars entered (excluding null terminator)

    cmp eax, 16
    jne invalidCard

    ; Validate all digits
    mov ecx, 0
    mov esi, OFFSET cardNumBuffer
validateCardLoop:
    mov al, [esi + ecx]
    cmp al, '0'
    jb invalidCard
    cmp al, '9'
    ja invalidCard
    inc ecx
    cmp ecx, 16
    jl validateCardLoop
    jmp getPIN

invalidCard:
    mov eax, hConsole
    mov cx, 04h
    INVOKE SetConsoleTextAttribute, eax, cx
    
    mov edx, OFFSET invalidCardMsg
    call WriteString
    
    mov cx, 0F5h
    INVOKE SetConsoleTextAttribute, eax, cx
    
    jmp getCardNumber

getPIN:
    mov edx, OFFSET promptCardPIN
    call WriteString

    call ReadMaskedPIN

    ; Verify PIN length
    mov esi, OFFSET pinBuffer
    mov ecx, 0
countPIN:
    cmp byte ptr [esi + ecx], 0
    je pinCounted
    inc ecx
    jmp countPIN
    
pinCounted:
    cmp ecx, 4
    jne invalidPIN

    ; Hash the PIN (simple XOR hash with rotation)
    xor eax, eax
    xor ecx, ecx
    mov esi, OFFSET pinBuffer
hashLoop:
    movzx ebx, BYTE PTR [esi + ecx]
    xor eax, ebx
    rol eax, 1           ; Rotate left for slightly better hashing
    inc ecx
    cmp ecx, 4
    jl hashLoop
    mov pinHash, eax

    ; Save card info to file
    INVOKE CreateFile,
        ADDR cardFilename,
        GENERIC_WRITE,
        0,               ; no sharing
        NULL,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        0
    mov fileHandle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je cardFileError

    INVOKE WriteFile,
        fileHandle,
        ADDR cardNumBuffer,
        16,
        ADDR writeCount,
        NULL

    INVOKE WriteFile,
        fileHandle,
        ADDR pinHash,
        SIZEOF pinHash,
        ADDR writeCount,
        NULL

    INVOKE CloseHandle, fileHandle

    mov edx, OFFSET cardSavedMsg
    call WriteString
    ret

invalidPIN:
    mov eax, hConsole
    mov cx, 04h
    INVOKE SetConsoleTextAttribute, eax, cx
    
    mov edx, OFFSET invalidPINMsg
    call WriteString
    
    mov cx, 0F5h
    INVOKE SetConsoleTextAttribute, eax, cx
    
    jmp getPIN

cardFileError:
    mov edx, OFFSET fileErrorMsg
    call WriteString
    ret
EnterCardDetails ENDP

ReadMaskedPIN PROC
    mov ecx, 0            ; counter
    mov esi, OFFSET pinBuffer
read_loop:
    call ReadChar         ; read one char
    cmp al, 0Dh           ; Enter key
    je check_len          ; if pressed enter early, check length
    cmp al, '0'
    jb invalid_char
    cmp al, '9'
    ja invalid_char

    ; Store digit and echo '*'
    mov [esi + ecx], al
    mov dl, '*'
    call WriteChar

    inc ecx
    cmp ecx, 4
    jl read_loop
    jmp pin_done

check_len:
    cmp ecx, 4
    je pin_done

invalid_char:
    ; Clear the buffer and start over
    mov ecx, 4
    mov edi, OFFSET pinBuffer
    xor al, al
    rep stosb
    
    mov eax, hConsole
    mov cx, 04h
    INVOKE SetConsoleTextAttribute, eax, cx
    
    mov edx, OFFSET invalidPINMsg
    call WriteString
    
    mov cx, 0F5h
    INVOKE SetConsoleTextAttribute, eax, cx
    
    mov edx, OFFSET promptCardPIN
    call WriteString
    mov ecx, 0
    jmp read_loop

pin_done:
    mov byte ptr [esi + ecx], 0 ; null terminate
    ret
ReadMaskedPIN ENDP

END main