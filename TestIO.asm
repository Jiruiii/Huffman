; ===============================================
; I/O 函式測試程式
; 用來測試所有檔案 I/O 函式是否正常運作
; ===============================================
INCLUDE Irvine32.inc

; 外部函式宣告（從 HuffmanGUI.asm）
OpenFileForRead PROTO, pszFilePath:PTR BYTE
OpenFileForWrite PROTO, pszFilePath:PTR BYTE
ReadFileByte PROTO, hFile:DWORD
WriteFileByte PROTO, hFile:DWORD, byteVal:BYTE
ReadFileBuffer PROTO, hFile:DWORD, pBuffer:PTR BYTE, nBytes:DWORD
WriteFileBuffer PROTO, hFile:DWORD, pBuffer:PTR BYTE, nBytes:DWORD
CloseFileHandle PROTO, hFile:DWORD
GetFileSizeEx PROTO, hFile:DWORD

.const
INVALID_HANDLE_VALUE EQU -1

.data
testFile    BYTE "test_input.txt", 0
outputFileBYTE "test_output.txt", 0
testData    BYTE "Hello, Huffman Coding!", 13, 10, 0
buffer      BYTE 256 DUP(0)

msgCreating BYTE "Creating test file...", 0
msgReading  BYTE "Reading test file...", 0
msgWriting  BYTE "Writing output file...", 0
msgSuccess  BYTE "All tests passed!", 0
msgError    BYTE "Error occurred!", 0
msgSize     BYTE "File size: ", 0
msgByte     BYTE "Byte read: ", 0
bytes       BYTE " bytes", 0

.code
main PROC
    call Clrscr
    
 ; ===== 測試 1: 建立並寫入測試檔案 =====
    mov edx, OFFSET msgCreating
    call WriteString
call Crlf
    
    INVOKE OpenFileForWrite, ADDR testFile
    .IF eax == INVALID_HANDLE_VALUE
 mov edx, OFFSET msgError
        call WriteString
        call Crlf
   jmp exit_program
    .ENDIF
    mov ebx, eax  ; 儲存 handle
    
    ; 使用 WriteFileBuffer 寫入資料
    mov ecx, LENGTHOF testData - 1
    INVOKE WriteFileBuffer, ebx, ADDR testData, ecx
  
    INVOKE CloseFileHandle, ebx
    call Crlf
    
    ; ===== 測試 2: 取得檔案大小 =====
    INVOKE OpenFileForRead, ADDR testFile
    mov ebx, eax
    
    INVOKE GetFileSizeEx, ebx
    mov edx, OFFSET msgSize
    call WriteString
    call WriteDec
    mov edx, OFFSET bytes
    call WriteString
    call Crlf
    call Crlf
    
    ; ===== 測試 3: 使用 ReadFileByte 逐位元組讀取 =====
    ; 先回到檔案開頭（重新開啟）
    INVOKE CloseFileHandle, ebx
    INVOKE OpenFileForRead, ADDR testFile
    mov ebx, eax
    
    mov edx, OFFSET msgReading
    call WriteString
    call Crlf
 
    mov ecx, 0  ; 計數器
read_loop:
    INVOKE ReadFileByte, ebx
    cmp eax, -1
    je read_done
    
; 顯示讀取的字元
    call WriteChar
    
    inc ecx
    jmp read_loop
    
read_done:
    call Crlf
    call Crlf
    
    INVOKE CloseFileHandle, ebx
    
    ; ===== 測試 4: 使用 ReadFileBuffer 批次讀取 =====
    INVOKE OpenFileForRead, ADDR testFile
    mov ebx, eax
    
    INVOKE ReadFileBuffer, ebx, ADDR buffer, 256
    mov ecx, eax  ; 讀取的位元組數
  
    INVOKE CloseFileHandle, ebx
    
    ; 寫入到輸出檔案
  mov edx, OFFSET msgWriting
    call WriteString
    call Crlf
    
    INVOKE OpenFileForWrite, ADDR outputFile
    mov ebx, eax
    
    INVOKE WriteFileBuffer, ebx, ADDR buffer, ecx
    
 INVOKE CloseFileHandle, ebx
    
    ; ===== 測試完成 =====
    call Crlf
    mov edx, OFFSET msgSuccess
    call WriteString
    call Crlf
    
exit_program:
    call WaitMsg
    INVOKE ExitProcess, 0
main ENDP

END main
