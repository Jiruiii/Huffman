; ===============================================
; Enhanced I/O Functions Test Program
; 測試所有增強功能
; ===============================================
INCLUDE Irvine32.inc

; 外部函式宣告
OpenFileForRead PROTO, pszFilePath:PTR BYTE
OpenFileForWrite PROTO, pszFilePath:PTR BYTE
ReadFileByte PROTO, hFile:DWORD
WriteFileByte PROTO, hFile:DWORD, byteVal:BYTE
ReadFileBuffer PROTO, hFile:DWORD, pBuffer:PTR BYTE, nBytes:DWORD
WriteFileBuffer PROTO, hFile:DWORD, pBuffer:PTR BYTE, nBytes:DWORD
CloseFileHandle PROTO, hFile:DWORD
GetFileSizeEx PROTO, hFile:DWORD
ValidateInputFile PROTO, pszFilePath:PTR BYTE
CopyFileData PROTO, pszSource:PTR BYTE, pszDest:PTR BYTE
CompareFiles PROTO, pszFile1:PTR BYTE, pszFile2:PTR BYTE
ClearBuffer PROTO, pBuffer:PTR BYTE, size:DWORD
GetCompressedFileSize PROTO, pszFilePath:PTR BYTE

.const
INVALID_HANDLE_VALUE EQU -1

.data
; 測試檔案
testFile1   BYTE "test_original.txt", 0
testFile2   BYTE "test_copy.txt", 0
testFile3   BYTE "test_output.txt", 0
emptyFile   BYTE "test_empty.txt", 0

; 測試資料
testData  BYTE "AAAAABBBBBCCCCCDDDDEEF", 13, 10
            BYTE "The quick brown fox jumps over the lazy dog.", 13, 10
            BYTE "Huffman coding test data!", 13, 10, 0
testDataSize EQU ($ - testData - 1)

buffer      BYTE 1024 DUP(0)

; 訊息
msgTest1    BYTE "=== Test 1: Create Test File ===", 0
msgTest2    BYTE "=== Test 2: Validate File ===", 0
msgTest3    BYTE "=== Test 3: Copy File ===", 0
msgTest4    BYTE "=== Test 4: Compare Files ===", 0
msgTest5    BYTE "=== Test 5: Buffer Operations ===", 0
msgTest6    BYTE "=== Test 6: Get File Size ===", 0
msgTest7    BYTE "=== Test 7: Empty File Test ===", 0

msgSuccess  BYTE "[PASS] ", 0
msgFail     BYTE "[FAIL] ", 0
msgSize     BYTE "File size: ", 0
msgBytes    BYTE " bytes", 0
msgSame     BYTE "Files are identical!", 0
msgDiff     BYTE "Files are different!", 0
msgCreated  BYTE "File created successfully", 0
msgCopied   BYTE "File copied successfully", 0
msgCleared  BYTE "Buffer cleared", 0

.code
main PROC
    call Clrscr
    
    call Test1_CreateFile
    call Crlf
    
    call Test2_ValidateFile
    call Crlf
    
    call Test3_CopyFile
    call Crlf
    
    call Test4_CompareFiles
    call Crlf
    
    call Test5_BufferOps
    call Crlf
    
    call Test6_GetFileSize
    call Crlf
    
    call Test7_EmptyFile
    call Crlf
    
    mov edx, OFFSET msgSuccess
    call WriteString
  mov edx, OFFSET msgSuccess
    call WriteString
    call WriteString
    mov al, 'A'
    call WriteChar
    mov al, 'L'
    call WriteChar
    mov al, 'L'
    call WriteChar
    mov al, ' '
call WriteChar
mov al, 'T'
  call WriteChar
    mov al, 'E'
    call WriteChar
    mov al, 'S'
    call WriteChar
    mov al, 'T'
    call WriteChar
    mov al, 'S'
    call WriteChar
    mov al, ' '
    call WriteChar
    mov al, 'C'
    call WriteChar
    mov al, 'O'
    call WriteChar
    mov al, 'M'
    call WriteChar
    mov al, 'P'
    call WriteChar
    mov al, 'L'
    call WriteChar
    mov al, 'E'
    call WriteChar
    mov al, 'T'
    call WriteChar
    mov al, 'E'
    call WriteChar
    mov al, 'D'
    call WriteChar
mov al, '!'
    call WriteChar
    call Crlf
  
    call WaitMsg
    INVOKE ExitProcess, 0
main ENDP

;-----------------------------------------------
; Test 1: 建立測試檔案
;-----------------------------------------------
Test1_CreateFile PROC
    LOCAL hFile:DWORD
    
    mov edx, OFFSET msgTest1
    call WriteString
 call Crlf
    
    ; 建立測試檔案
    INVOKE OpenFileForWrite, ADDR testFile1
    .IF eax == INVALID_HANDLE_VALUE
        mov edx, OFFSET msgFail
        call WriteString
        mov edx, OFFSET msgCreated
        call WriteString
 call Crlf
  ret
    .ENDIF
    mov hFile, eax
    
    ; 寫入測試資料
    INVOKE WriteFileBuffer, hFile, ADDR testData, testDataSize
    
    INVOKE CloseFileHandle, hFile
    
    mov edx, OFFSET msgSuccess
    call WriteString
    mov edx, OFFSET msgCreated
    call WriteString
    call Crlf
 
    ret
Test1_CreateFile ENDP

;-----------------------------------------------
; Test 2: 驗證檔案
;-----------------------------------------------
Test2_ValidateFile PROC
    mov edx, OFFSET msgTest2
    call WriteString
    call Crlf
    
    INVOKE ValidateInputFile, ADDR testFile1
    .IF eax == 0
        mov edx, OFFSET msgFail
        call WriteString
        mov al, 'V'
        call WriteChar
        mov al, 'a'
  call WriteChar
        mov al, 'l'
  call WriteChar
        mov al, 'i'
        call WriteChar
        mov al, 'd'
        call WriteChar
      mov al, 'a'
        call WriteChar
        mov al, 't'
   call WriteChar
        mov al, 'i'
        call WriteChar
        mov al, 'o'
        call WriteChar
        mov al, 'n'
  call WriteChar
        call Crlf
        ret
    .ENDIF
    
    mov edx, OFFSET msgSuccess
    call WriteString
    mov edx, OFFSET msgSize
    call WriteString
    call WriteDec
    mov edx, OFFSET msgBytes
  call WriteString
    call Crlf
    
    ret
Test2_ValidateFile ENDP

;-----------------------------------------------
; Test 3: 複製檔案
;-----------------------------------------------
Test3_CopyFile PROC
    mov edx, OFFSET msgTest3
    call WriteString
    call Crlf
    
    INVOKE CopyFileData, ADDR testFile1, ADDR testFile2
    .IF eax == 0
        mov edx, OFFSET msgFail
   call WriteString
 mov edx, OFFSET msgCopied
    call WriteString
        call Crlf
        ret
    .ENDIF
    
    mov edx, OFFSET msgSuccess
    call WriteString
    mov edx, OFFSET msgCopied
  call WriteString
    call Crlf
    
    ret
Test3_CopyFile ENDP

;-----------------------------------------------
; Test 4: 比較檔案
;-----------------------------------------------
Test4_CompareFiles PROC
mov edx, OFFSET msgTest4
    call WriteString
    call Crlf
    
    INVOKE CompareFiles, ADDR testFile1, ADDR testFile2
    .IF eax == 0
        mov edx, OFFSET msgFail
   call WriteString
        mov edx, OFFSET msgDiff
      call WriteString
        call Crlf
  ret
    .ENDIF
 
    mov edx, OFFSET msgSuccess
    call WriteString
    mov edx, OFFSET msgSame
    call WriteString
    call Crlf
    
    ret
Test4_CompareFiles ENDP

;-----------------------------------------------
; Test 5: 緩衝區操作
;-----------------------------------------------
Test5_BufferOps PROC
    mov edx, OFFSET msgTest5
    call WriteString
    call Crlf
    
    ; 填入資料
    mov edi, OFFSET buffer
    mov ecx, 10
    mov al, 'X'
fill_loop:
    mov [edi], al
    inc edi
    loop fill_loop
    
    ; 清空緩衝區
    INVOKE ClearBuffer, ADDR buffer, 1024
    
    ; 檢查是否清空
    mov esi, OFFSET buffer
    mov ecx, 1024
check_loop:
    lodsb
    cmp al, 0
    jne buffer_fail
    loop check_loop
    
    mov edx, OFFSET msgSuccess
    call WriteString
    mov edx, OFFSET msgCleared
    call WriteString
    call Crlf
    ret
    
buffer_fail:
    mov edx, OFFSET msgFail
    call WriteString
    mov edx, OFFSET msgCleared
    call WriteString
    call Crlf
    ret
Test5_BufferOps ENDP

;-----------------------------------------------
; Test 6: 取得檔案大小
;-----------------------------------------------
Test6_GetFileSize PROC
    mov edx, OFFSET msgTest6
    call WriteString
    call Crlf
    
    INVOKE GetCompressedFileSize, ADDR testFile1
    .IF eax == 0
        mov edx, OFFSET msgFail
        call WriteString
        call Crlf
        ret
    .ENDIF
    
    mov edx, OFFSET msgSuccess
  call WriteString
    mov edx, OFFSET msgSize
    call WriteString
    call WriteDec
    mov edx, OFFSET msgBytes
    call WriteString
    call Crlf
    
    ret
Test6_GetFileSize ENDP

;-----------------------------------------------
; Test 7: 空檔案測試
;-----------------------------------------------
Test7_EmptyFile PROC
    LOCAL hFile:DWORD
    
    mov edx, OFFSET msgTest7
    call WriteString
    call Crlf
    
 ; 建立空檔案
    INVOKE OpenFileForWrite, ADDR emptyFile
    mov hFile, eax
    INVOKE CloseFileHandle, hFile
    
    ; 驗證空檔案（應該失敗）
    INVOKE ValidateInputFile, ADDR emptyFile
    .IF eax == 0
        mov edx, OFFSET msgSuccess
        call WriteString
      mov al, 'E'
  call WriteChar
  mov al, 'm'
        call WriteChar
    mov al, 'p'
call WriteChar
        mov al, 't'
        call WriteChar
        mov al, 'y'
  call WriteChar
        mov al, ' '
        call WriteChar
        mov al, 'f'
        call WriteChar
        mov al, 'i'
        call WriteChar
        mov al, 'l'
        call WriteChar
        mov al, 'e'
      call WriteChar
        mov al, ' '
     call WriteChar
        mov al, 'c'
   call WriteChar
        mov al, 'o'
        call WriteChar
      mov al, 'r'
     call WriteChar
        mov al, 'r'
        call WriteChar
   mov al, 'e'
    call WriteChar
  mov al, 'c'
        call WriteChar
        mov al, 't'
        call WriteChar
        mov al, 'l'
        call WriteChar
        mov al, 'y'
        call WriteChar
 mov al, ' '
        call WriteChar
        mov al, 'r'
        call WriteChar
     mov al, 'e'
        call WriteChar
        mov al, 'j'
        call WriteChar
 mov al, 'e'
call WriteChar
  mov al, 'c'
     call WriteChar
      mov al, 't'
        call WriteChar
   mov al, 'e'
        call WriteChar
        mov al, 'd'
        call WriteChar
 call Crlf
        ret
    .ENDIF
    
    mov edx, OFFSET msgFail
    call WriteString
    call Crlf
    ret
Test7_EmptyFile ENDP

END main
