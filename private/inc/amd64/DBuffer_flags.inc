
;
; If the value of the double buffer is 0, then don't
; plot it in the frame. This is transparancy.  
;
DB_FLAG_TRANSPARENT_ZERO EQU <1>

;
; If the value of the double buffer is 0, then
; directly plot zero ignoring the pallete.
;
DB_FLAG_ZERO_IGNORES_PAL EQU <2>

;
; As each pixel is plotted, zero out the buffer.
; 
;
DB_FLAG_CLEAR_BUFFER     EQU <4>