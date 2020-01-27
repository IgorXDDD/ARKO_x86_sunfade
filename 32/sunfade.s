    section .text

    global sunfade

; arguments
%define img         [ebp+8]
%define width       [ebp+12]
%define height      [ebp+16]
%define dist        [ebp+20]
%define x_circle    [ebp+24]
%define y_circle    [ebp+28]

; local variables
%define row_bytes   [ebp-4]
%define dx_2        [ebp-8]
%define dy_2        [ebp-12]
%define d_2         [ebp-16]
%define x           [ebp-20]
%define y           [ebp-24]
%define dist_2      [ebp-28]


sunfade:
    ; prolog
    push    ebp
    mov     ebp, esp
    sub     esp, 28     ; 7 variables, 7 x 4

    ; saving all used registers
    push    ebx
    push    esi
    push    edi

    ; img source
    mov     esi, img        ; image starts with pixels (handeld in C program)
                            ; esi points to the begining of current line (row)
                            ; it's incremented by row width (row_bytes) after every line iteration

    ; calculate row size
    mov     eax, width      ; row size in pixels
    lea     eax, [eax+eax*2]  ; row size* in bytes (3 bytes per pixel -3 subpixels)  
    ;mul    eax, 3          ; row size* in bytes (3 bytes per pixel -3 subpixels)
    add     eax, 3          ; 3 is the maximum value to fit on 2 least significant bits
    and     eax, 0fffffffch ; zero out 2 least significant bits, to round up to multiple of 4

    mov     row_bytes, eax  ; row size in bytes (multiple of 4, padding is handled)

    mov     ecx, height     ; ecx  - how many lines (rows) are left  to go?



;____________________ Algorithm begins _____________________ 

next_line:
    ; edi - how many pixels are left to be porcesed in this line?
    mov     edi, width      ; set after every line proceeding
    ; single pixel index (one for every 3 subpixels)
    xor     ebx, ebx        ; reset index

fade:

    push    ebx         ; remember the index

    xor     edx, edx    ; edx zero'ed before division

    mov     eax, ebx    ; eax = index,      we're moving 3 bytes per pixel
    mov     ebx, 3      ; ebx = 3           so x cord is gotten by dividing by 3
    div     ebx         ; eax = index/3
    mov     x, eax      ; x cord


    mov     eax, height ; eax = height
    sub     eax, ecx    ; y = height - lines amount left
    mov     y, eax      ; y cord


    mov     eax, x_circle
    sub     eax, x      ; eax = dx = x_circle - x, x difference
    imul    eax, eax    ; eax = (dx * dx)
    mov     dx_2, eax   ; dx_2 = dx^2


    mov     eax, y_circle
    sub     eax, y      ; eax = dy = y_circle - y, y difference  
    imul    eax, eax    ; eax = (dy * dy)
    mov     dy_2, eax   ; dy_2 = dy^2


    mov     eax, dist
    imul    eax, eax    ; eax = dist^2 (dist * dist)
    mov     dist_2, eax ; dist_2 = dist^2


    pop     ebx         ; recall the index

    mov     eax, dx_2   ; Pythagorean theorem
    add     eax, dy_2   ; eax = (dx^2 +dy^2) 
    mov     d_2, eax        ; d_2 = d^2 = (dx^2 +dy^2) 
    cmp     eax, dist_2     ; d^2 - dist^2
    jae     next_pix   ; if d^2 >= dist^2 then there is no need to change anything, go to the next pixel

  
;   ---------- SUNFADING EVERY SUBPIXEL ----------
; everything is multiplied and then divided by 256 (2^8)
; without it, program didn't work properly - there was no fading, just white circle

    ; saving registers
    push    ecx         ; counter of lines to proceed
    push    edi

    xor     edx, edx    ;edx zero'ed before division, after division edx is concatenated

    push    ebx         ; pixel index in a line - current pixel
    
    mov     eax, d_2
    shl     eax, 8      ; eax = d_2 * 256, without it coefficient woudld be zero
    mov     ebx, dist_2
    div     ebx         ; eax = 256*(d^2) / dist^2

    mov     ecx, eax    ; ecx = (fading coefficient)*256 = 256*(d^2) / dist^2
    ; to tutaj wystarczy tylko raz
    pop     ebx

    movzx   edx, byte [esi+ebx+0]   ; Get the blue subpixel

    ; fading formula: 255 - (255-color)*(d^2/dist^2)
    ; d - distance between circle center and procesed pixel

    mov     al, 255
    sub     al, dl
    mul     cl   

    mov     al, 255
    sub     al, ah

    mov     [esi+ebx+0], al     ; save blue

;_____________________________next pixel (green)

    movzx   edx, byte [esi+ebx+1]   ; Get the green subpixel

    ; fading formula: 255 - (255-color)*(d^2/dist^2)
    ; d - distance between circle center and procesed pixel

    mov     al, 255
    sub     al, dl
    mul     cl   

    mov     al, 255
    sub     al, ah

    mov     [esi+ebx+1], al     ; save green

;_____________________________next pixel (red)

    movzx   edx, byte [esi+ebx+2]   ; Get the red subpixel

    ; fading formula: 255 - (255-color)*(d^2/dist^2)
    ; d - distance between circle center and procesed pixel

    mov     al, 255
    sub     al, dl
    mul     cl    

    mov     al, 255
    sub     al, ah

    mov     [esi+ebx+2], al     ; save red

;__________________________________________________________________________________________  
;   ====================== FADING OF THIS PIXEL IS COMPLETED ======================
    pop     edi
    pop     ecx


next_pix:
    add     ebx, 3      ; go to next pixel (move 24 b - 3 subpixles)    
    dec     edi         ; one less pixel to process in line
    jnz     fade        ; is line already over? if no go to next pixel

    add     esi, row_bytes  ; if it is over (if the row is over)
    dec     ecx             ; decrement lines to proceed amount
    jnz     next_line       ; if not 0, continue to next line

    ; epliog
    pop     edi
    pop     esi
    pop     ebx

    mov     esp, ebp
    pop     ebp

    ret
