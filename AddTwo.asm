INCLUDE Irvine32.inc  ; 引入 Irvine 函式庫

.data
message BYTE "Irvine setup successful!", 0  ; 要顯示的字串

.code
main PROC               ; 進入點是 main
    mov edx, OFFSET message ; 將 message 的位址放入 edx
    call WriteString        ; 呼叫 Irvine 函數來印出字串
    call Crlf               ; 呼叫 Irvine 函數來換行

    exit                    ; 使用 Irvine 的 exit 巨集來結束程式
main ENDP

END main                ; 程式結束點是 main