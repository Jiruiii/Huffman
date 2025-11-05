; ===============================================
; 範例：給人員二的參考程式碼
; 展示如何使用人員一提供的 I/O 函式來統計字元頻率
; ===============================================
INCLUDE Irvine32.inc

; 引入人員一的 I/O 函式
OpenFileForRead PROTO, pszFilePath:PTR BYTE
ReadFileByte PROTO, hFile:DWORD
CloseFileHandle PROTO, hFile:DWORD
GetFileSizeEx PROTO, hFile:DWORD

.const
INVALID_HANDLE_VALUE EQU -1

.data
; 頻率統計陣列（0-255 每個 byte 值）
frequency DWORD 256 DUP(0)

testFile BYTE "input.txt", 0

msgAnalyzing BYTE "Analyzing file...", 0
msgFreq   BYTE "Character frequency:", 0
msgChar      BYTE "Char: ", 0
msgCount     BYTE " Count: ", 0

.code
main PROC
    call Clrscr
    
    ; 呼叫統計函式
    INVOKE AnalyzeFileFrequency, ADDR testFile
    
    ; 顯示結果
    call DisplayFrequency
    
    call WaitMsg
    INVOKE ExitProcess, 0
main ENDP

;-----------------------------------------------
; AnalyzeFileFrequency
; 統計檔案中每個位元組的出現頻率
; 參數：pszFilePath - 檔案路徑
; 傳回：EAX = 檔案總位元組數（-1 表示錯誤）
;-----------------------------------------------
AnalyzeFileFrequency PROC USES ebx ecx edx, pszFilePath:PTR BYTE
    LOCAL hFile:DWORD
    LOCAL totalBytes:DWORD
    
    ; 清空頻率陣列
    mov edi, OFFSET frequency
    mov ecx, 256
    xor eax, eax
rep stosd
    
    ; 開啟檔案
    INVOKE OpenFileForRead, pszFilePath
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, -1
        ret
    .ENDIF
    mov hFile, eax
    
    ; 顯示訊息
    mov edx, OFFSET msgAnalyzing
    call WriteString
    call Crlf
    
    ; 初始化計數器
    mov totalBytes, 0
    
    ; 逐位元組讀取並統計
read_loop:
    INVOKE ReadFileByte, hFile
    cmp eax, -1
    je read_done
    
    ; EAX 中是讀取的位元組值（0-255）
    movzx ebx, al      ; 將 byte 值延伸到 32-bit
    shl ebx, 2            ; 乘以 4（DWORD 大小）
    inc frequency[ebx]     ; 增加該位元組的頻率
    
    inc totalBytes         ; 總位元組數 +1
    
    jmp read_loop
    
read_done:
  ; 關閉檔案
    INVOKE CloseFileHandle, hFile
    
    mov eax, totalBytes
    ret
AnalyzeFileFrequency ENDP

;-----------------------------------------------
; DisplayFrequency
; 顯示頻率統計結果（只顯示出現過的字元）
;-----------------------------------------------
DisplayFrequency PROC USES eax ebx ecx edx
  mov edx, OFFSET msgFreq
    call WriteString
    call Crlf
    call Crlf
    
    mov ecx, 0  ; 字元計數器（0-255）
display_loop:
    ; 取得頻率值
    mov ebx, ecx
    shl ebx, 2        ; * 4
    mov eax, frequency[ebx]
    
    ; 如果頻率 > 0，顯示
    .IF eax > 0
        ; 顯示字元
        mov edx, OFFSET msgChar
        call WriteString
   
        .IF ecx >= 32 && ecx <= 126
            ; 可印字元
            mov al, cl
   call WriteChar
    .ELSE
            ; 不可印字元，顯示其值
            mov eax, ecx
          call WriteDec
      .ENDIF
     
    ; 顯示頻率
        mov edx, OFFSET msgCount
        call WriteString
     mov ebx, ecx
shl ebx, 2
        mov eax, frequency[ebx]
        call WriteDec
        call Crlf
 .ENDIF
    
    inc ecx
    cmp ecx, 256
    jl display_loop
    
    ret
DisplayFrequency ENDP

END main

; ===============================================
; 人員二可以將此程式改寫為：
; 
; BuildHuffmanTree PROC, pszFilePath:PTR BYTE
;     ; 1. 呼叫 AnalyzeFileFrequency 統計頻率
;     INVOKE AnalyzeFileFrequency, pszFilePath
;     
;     ; 2. 建立優先佇列（Priority Queue）
;     ;    - 為每個出現的字元建立葉節點
;     ;    - 將節點按頻率由小到大排序
;     
;     ; 3. 建立霍夫曼樹
;;    WHILE 佇列中節點數 > 1
;     ;        取出頻率最小的兩個節點 left, right
;     ;     建立新節點 parent
;     ;        parent.freq = left.freq + right.freq
;     ;    parent.left = left
;;        parent.right = right
;     ;        將 parent 放回佇列
;     ;    END WHILE
;     
;     ; 4. 傳回樹根節點指標
;     mov eax, pTreeRoot
;     ret
; BuildHuffmanTree ENDP
; ===============================================
