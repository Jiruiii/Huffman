; ===============================================
; Huffman Coding File Compression Tool
; 人員一：GUI 與檔案 I/O 總管 (Enhanced Version)
; ===============================================
INCLUDE Irvine32.inc
INCLUDE macros.inc

; Windows API 宣告
GetModuleHandleA PROTO, lpModuleName:PTR BYTE
DialogBoxParamA PROTO, hInstance:DWORD, lpTemplateName:DWORD, hWndParent:DWORD, lpDialogFunc:DWORD, dwInitParam:DWORD
EndDialog PROTO, hDlg:DWORD, nResult:DWORD
GetDlgItem PROTO, hDlg:DWORD, nIDDlgItem:DWORD
SetWindowTextA PROTO, hWnd:DWORD, lpString:PTR BYTE
GetOpenFileNameA PROTO, lpofn:PTR OPENFILENAME
GetSaveFileNameA PROTO, lpofn:PTR OPENFILENAME

; 檔案 I/O API
CreateFileA PROTO, lpFileName:PTR BYTE, dwDesiredAccess:DWORD, dwShareMode:DWORD,
    lpSecurityAttributes:DWORD, dwCreationDisposition:DWORD, dwFlagsAndAttributes:DWORD, hTemplateFile:DWORD
; ReadFile and WriteFile are already defined in Windows libraries
CloseHandle PROTO, hObject:DWORD
GetFileSize PROTO, hFile:DWORD, lpFileSizeHigh:DWORD
; SetFilePointer is already defined in Windows libraries
MessageBoxA PROTO, hWnd:DWORD, lpText:PTR BYTE, lpCaption:PTR BYTE, uType:DWORD

; String 函式
wsprintfA PROTO C, lpOut:PTR BYTE, lpFmt:PTR BYTE, args:VARARG

; 常數定義
.const
IDD_MAIN_DIALOG  EQU 101
IDC_BTN_COMPRESS    EQU 1001
IDC_BTN_DECOMPRESS  EQU 1002
IDC_EDIT_STATUS     EQU 1003
IDC_BTN_EXIT        EQU 1004

WM_INITDIALOG       EQU 0110h
WM_COMMAND        EQU 0111h
WM_CLOSE            EQU 0010h

GENERIC_READ        EQU 80000000h
GENERIC_WRITE       EQU 40000000h
CREATE_ALWAYS     EQU 2
OPEN_EXISTING       EQU 3
FILE_ATTRIBUTE_NORMAL EQU 80h
INVALID_HANDLE_VALUE EQU -1
FILE_BEGIN   EQU 0
FILE_CURRENT        EQU 1
FILE_END    EQU 2

OFN_FILEMUSTEXIST   EQU 1000h
OFN_PATHMUSTEXIST   EQU 800h
OFN_OVERWRITEPROMPT EQU 2h

MB_OK          EQU 0
MB_ICONINFORMATION  EQU 40h
MB_ICONERROR        EQU 10h
MB_ICONWARNING    EQU 30h

; OPENFILENAME 結構
OPENFILENAME STRUCT
    lStructSize       DWORD ?
    hwndOwner DWORD ?
    hInstance       DWORD ?
    lpstrFilter       DWORD ?
    lpstrCustomFilter DWORD ?
    nMaxCustFilter DWORD ?
    nFilterIndex      DWORD ?
    lpstrFile     DWORD ?
    nMaxFile          DWORD ?
    lpstrFileTitle    DWORD ?
    nMaxFileTitle     DWORD ?
    lpstrInitialDir   DWORD ?
    lpstrTitle        DWORD ?
  Flags             DWORD ?
    nFileOffset       WORD  ?
    nFileExtension    WORD  ?
    lpstrDefExt       DWORD ?
  lCustData    DWORD ?
    lpfnHook DWORD ?
    lpTemplateName    DWORD ?
OPENFILENAME ENDS

.data
; 全域變數
hInstance  DWORD ?
hMainDialog     DWORD ?
szInputFile     BYTE 260 DUP(0)
szOutputFile    BYTE 260 DUP(0)
inputFileSize   DWORD ?
outputFileSize  DWORD ?

; 檔案過濾器
szFilterCompress    BYTE "Text Files (*.txt)",0,"*.txt",0
      BYTE "All Files (*.*)",0,"*.*",0,0
szFilterDecompress  BYTE "Huffman Files (*.huf)",0,"*.huf",0
         BYTE "All Files (*.*)",0,"*.*",0,0
szFilterSave        BYTE "Huffman Files (*.huf)",0,"*.huf",0
            BYTE "Text Files (*.txt)",0,"*.txt",0,0

; 訊息字串
szAppTitle  BYTE "Huffman File Compressor v1.0",0
szCompressTitle     BYTE "Select File to Compress",0
szDecompressTitle   BYTE "Select File to Decompress",0
szSaveTitle     BYTE "Save Compressed File As",0
szStatus   BYTE "Ready. Please select an operation.",0
szCompressing       BYTE "Compressing file...",0
szDecompressing   BYTE "Decompressing file...",0
szSuccess     BYTE "Operation completed successfully!",0
szError  BYTE "Error",0
szFileError         BYTE "Cannot open file!",0
szNoFileSelected    BYTE "No file selected!",0
szFileNotExist      BYTE "File does not exist!",0
szFileTooLarge  BYTE "File is too large (max 10MB)!",0
szEmptyFile         BYTE "File is empty!",0

; 統計訊息格式字串
szStatsFormat       BYTE "Input: %d bytes | Output: %d bytes | Compression: %d%%",0
szDecompStatsFormat BYTE "Decompressed: %d bytes from %d bytes compressed file",0
szReadyWithFile     BYTE "Selected: %s (%d bytes)",0

; 緩衝區
szStatusBuffer      BYTE 512 DUP(0)
szMessageBuffer  BYTE 512 DUP(0)

; 副檔名資料
hufExt BYTE ".huf",0
txtExt BYTE ".txt",0

; 測試訊息
szDebugMsg BYTE "Building Huffman Tree...",0

; 前向宣告 (Forward Declarations)
DlgProc PROTO, hDlg:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
CompressFile PROTO
DecompressFile PROTO
SetupOpenFileStruct PROTO, pOfn:PTR OPENFILENAME, pFile:PTR BYTE, pFilter:PTR BYTE, pTitle:PTR BYTE
ValidateInputFile PROTO, pszFilePath:PTR BYTE
DisplayCompressionStats PROTO
DisplayDecompressionStats PROTO
SelectSaveFile PROTO
SelectSaveFileDecompress PROTO
GenerateOutputFilename PROTO, pszInput:PTR BYTE, pszOutput:PTR BYTE, pszExtension:PTR BYTE
SetupSaveFileStruct PROTO, pOfn:PTR OPENFILENAME, pFile:PTR BYTE, pFilter:PTR BYTE
ClearBuffer PROTO, pBuffer:PTR BYTE, bufSize:DWORD
UpdateStatus PROTO, pszMessage:PTR BYTE
GetCompressedFileSize PROTO, pszFilePath:PTR BYTE
OpenFileForRead PROTO, pszFilePath:PTR BYTE
OpenFileForWrite PROTO, pszFilePath:PTR BYTE
ReadFileByte PROTO, hFile:DWORD
WriteFileByte PROTO, hFile:DWORD, byteVal:BYTE
ReadFileBuffer PROTO, hFile:DWORD, pBuffer:PTR BYTE, nBytes:DWORD
WriteFileBuffer PROTO, hFile:DWORD, pBuffer:PTR BYTE, nBytes:DWORD
CloseFileHandle PROTO, hFile:DWORD
GetFileSizeEx PROTO, hFile:DWORD
SeekFile PROTO, hFile:DWORD, distanceToMove:SDWORD, moveMethod:DWORD
CopyFileData PROTO, pszSource:PTR BYTE, pszDest:PTR BYTE
CompareFiles PROTO, pszFile1:PTR BYTE, pszFile2:PTR BYTE

.code

;-----------------------------------------------
; 主程式進入點
;-----------------------------------------------
main PROC
    INVOKE GetModuleHandleA, NULL
    mov hInstance, eax
    
    ; 顯示主對話框
    INVOKE DialogBoxParamA, hInstance, IDD_MAIN_DIALOG, NULL, ADDR DlgProc, 0
    
    INVOKE ExitProcess, 0
main ENDP

;-----------------------------------------------
; 對話框處理程序
;-----------------------------------------------
DlgProc PROC, hDlg:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    .IF uMsg == WM_INITDIALOG
        mov eax, hDlg
     mov hMainDialog, eax
        INVOKE GetDlgItem, hDlg, IDC_EDIT_STATUS
        INVOKE SetWindowTextA, eax, ADDR szStatus
        mov eax, TRUE
        ret
        
    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam
        and eax, 0FFFFh
      
     .IF eax == IDC_BTN_COMPRESS
       call CompressFile
    .ELSEIF eax == IDC_BTN_DECOMPRESS
            call DecompressFile
        .ELSEIF eax == IDC_BTN_EXIT
       INVOKE EndDialog, hDlg, 0
        .ENDIF
 
    .ELSEIF uMsg == WM_CLOSE
        INVOKE EndDialog, hDlg, 0
    .ENDIF
    
    mov eax, FALSE
    ret
DlgProc ENDP

;-----------------------------------------------
; 壓縮檔案流程（增強版）
;-----------------------------------------------
CompressFile PROC
    LOCAL ofn:OPENFILENAME
    LOCAL hFile:DWORD
    
    ; 清除檔案路徑緩衝區
    INVOKE ClearBuffer, ADDR szInputFile, 260
    INVOKE ClearBuffer, ADDR szOutputFile, 260
    
    ; 設定 OPENFILENAME 結構
    INVOKE SetupOpenFileStruct, ADDR ofn, ADDR szInputFile, ADDR szFilterCompress, ADDR szCompressTitle
 
    ; 顯示開啟檔案對話框
    INVOKE GetOpenFileNameA, ADDR ofn
    .IF eax == 0
        ret
    .ENDIF

    ; 驗證檔案
    INVOKE ValidateInputFile, ADDR szInputFile
    .IF eax == 0
  ret
    .ENDIF
    mov inputFileSize, eax
    
    ; 顯示檔案資訊
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szReadyWithFile, ADDR szInputFile, inputFileSize
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; 顯示輸出檔案
    call SelectSaveFile
    .IF eax == 0
        ret
    .ENDIF
    
    ; 更新狀態
    INVOKE UpdateStatus, ADDR szCompressing
    
    ; TODO: 在這裡呼叫人員二、三的函式
    ; INVOKE BuildHuffmanTree, ADDR szInputFile
    ; mov pTreeRoot, eax
    ; .IF eax != NULL
    ;     INVOKE CompressWithHuffman, pTreeRoot, ADDR szInputFile, ADDR szOutputFile
    ;     .IF eax != 0
    ;         ; 壓縮成功，顯示統計
    ;         INVOKE GetCompressedFileSize, ADDR szOutputFile
    ;      mov outputFileSize, eax
    ;  INVOKE DisplayCompressionStats
    ;     .ENDIF
    ; .ENDIF
    
    ; 模擬壓縮（暫時）
    mov eax, inputFileSize
    shr eax, 1  ; 假設壓縮率 50%
    mov outputFileSize, eax
    
    ; 顯示統計資訊
    call DisplayCompressionStats
    
    ; 顯示完成訊息框
    INVOKE MessageBoxA, hMainDialog, ADDR szSuccess, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    INVOKE UpdateStatus, ADDR szStatus
    
    ret
CompressFile ENDP

;-----------------------------------------------
; 解壓縮檔案流程（增強版）
;-----------------------------------------------
DecompressFile PROC
    LOCAL ofn:OPENFILENAME
    LOCAL hFile:DWORD
    
    ; 清除檔案路徑緩衝區
    INVOKE ClearBuffer, ADDR szInputFile, 260
    INVOKE ClearBuffer, ADDR szOutputFile, 260
    
    ; 設定 OPENFILENAME 結構
    INVOKE SetupOpenFileStruct, ADDR ofn, ADDR szInputFile, ADDR szFilterDecompress, ADDR szDecompressTitle
 
    ; 顯示開啟檔案對話框
    INVOKE GetOpenFileNameA, ADDR ofn
    .IF eax == 0
        ret
    .ENDIF
    
    ; 驗證檔案
    INVOKE ValidateInputFile, ADDR szInputFile
    .IF eax == 0
      ret
    .ENDIF
    mov inputFileSize, eax
    
    ; 顯示檔案資訊
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szReadyWithFile, ADDR szInputFile, inputFileSize
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; 顯示輸出檔案
    call SelectSaveFileDecompress
    .IF eax == 0
        ret
    .ENDIF
    
    ; 更新狀態
    INVOKE UpdateStatus, ADDR szDecompressing
    
    ; TODO: 在這裡呼叫人員四的函式
    ; INVOKE DecompressHuffmanFile, ADDR szInputFile, ADDR szOutputFile
    ; .IF eax != 0
    ;     ; 解壓縮成功，顯示統計
    ;     INVOKE GetCompressedFileSize, ADDR szOutputFile
    ;     mov outputFileSize, eax
    ;     INVOKE DisplayDecompressionStats
    ; .ENDIF
    
    ; 模擬解壓縮（暫時）
    mov eax, inputFileSize
shl eax, 1  ; 假設還原為 2 倍
    mov outputFileSize, eax
    
    ; 顯示統計資訊
    call DisplayDecompressionStats
    
    ; 顯示完成訊息框
  INVOKE MessageBoxA, hMainDialog, ADDR szSuccess, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    INVOKE UpdateStatus, ADDR szStatus
    
    ret
DecompressFile ENDP

;-----------------------------------------------
; 設定 OPENFILENAME 結構的輔助函式
;-----------------------------------------------
SetupOpenFileStruct PROC USES ebx, pOfn:PTR OPENFILENAME, pFile:PTR BYTE, pFilter:PTR BYTE, pTitle:PTR BYTE
    mov ebx, pOfn
    
    mov eax, SIZEOF OPENFILENAME
    mov (OPENFILENAME PTR [ebx]).lStructSize, eax
    mov eax, hMainDialog
    mov (OPENFILENAME PTR [ebx]).hwndOwner, eax
    mov eax, hInstance
    mov (OPENFILENAME PTR [ebx]).hInstance, eax
    mov eax, pFilter
    mov (OPENFILENAME PTR [ebx]).lpstrFilter, eax
 mov (OPENFILENAME PTR [ebx]).lpstrCustomFilter, NULL
    mov (OPENFILENAME PTR [ebx]).nMaxCustFilter, 0
    mov (OPENFILENAME PTR [ebx]).nFilterIndex, 1
    mov eax, pFile
    mov (OPENFILENAME PTR [ebx]).lpstrFile, eax
    mov (OPENFILENAME PTR [ebx]).nMaxFile, 260
    mov (OPENFILENAME PTR [ebx]).lpstrFileTitle, NULL
    mov (OPENFILENAME PTR [ebx]).nMaxFileTitle, 0
    mov (OPENFILENAME PTR [ebx]).lpstrInitialDir, NULL
    mov eax, pTitle
  mov (OPENFILENAME PTR [ebx]).lpstrTitle, eax
    mov (OPENFILENAME PTR [ebx]).Flags, OFN_FILEMUSTEXIST OR OFN_PATHMUSTEXIST
    mov (OPENFILENAME PTR [ebx]).nFileOffset, 0
    mov (OPENFILENAME PTR [ebx]).nFileExtension, 0
    mov (OPENFILENAME PTR [ebx]).lpstrDefExt, NULL
  mov (OPENFILENAME PTR [ebx]).lCustData, 0
  mov (OPENFILENAME PTR [ebx]).lpfnHook, NULL
 mov (OPENFILENAME PTR [ebx]).lpTemplateName, NULL
    
    ret
SetupOpenFileStruct ENDP

;-----------------------------------------------
; 驗證輸入檔案
; 傳回：EAX = 檔案大小（成功）或 0（失敗）
;-----------------------------------------------
ValidateInputFile PROC USES ebx, pszFilePath:PTR BYTE
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    
    ; 開啟檔案
    INVOKE OpenFileForRead, pszFilePath
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE MessageBoxA, hMainDialog, ADDR szFileError, ADDR szError, MB_OK OR MB_ICONERROR
        xor eax, eax
    ret
    .ENDIF
    mov hFile, eax
    
    ; 取得檔案大小
    INVOKE GetFileSize, hFile, NULL
    .IF eax == -1
        INVOKE CloseHandle, hFile
        INVOKE MessageBoxA, hMainDialog, ADDR szFileError, ADDR szError, MB_OK OR MB_ICONERROR
        xor eax, eax
        ret
    .ENDIF
    mov fileSize, eax
    
    ; 檢查是否為空檔案
    .IF fileSize == 0
        INVOKE CloseHandle, hFile
        INVOKE MessageBoxA, hMainDialog, ADDR szEmptyFile, ADDR szError, MB_OK OR MB_ICONWARNING
    xor eax, eax
        ret
    .ENDIF
    
    ; 檢查檔案大小（限制 10MB）
    .IF fileSize > 10485760
        INVOKE CloseHandle, hFile
        INVOKE MessageBoxA, hMainDialog, ADDR szFileTooLarge, ADDR szError, MB_OK OR MB_ICONWARNING
        xor eax, eax
        ret
    .ENDIF
    
    INVOKE CloseHandle, hFile
    mov eax, fileSize
    ret
ValidateInputFile ENDP

;-----------------------------------------------
; 顯示壓縮統計資訊
;-----------------------------------------------
DisplayCompressionStats PROC USES eax ebx ecx edx
    LOCAL compressionRatio:DWORD
    
    ; 計算壓縮率 = (1 - compressed/original) * 100
    mov eax, outputFileSize
    mov ebx, 100
    mul ebx
    mov ebx, inputFileSize
    .IF ebx != 0
  div ebx
        mov compressionRatio, eax
   mov eax, 100
        sub eax, compressionRatio
  mov compressionRatio, eax
    .ELSE
        mov compressionRatio, 0
    .ENDIF
    
    ; 格式化訊息
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szStatsFormat, 
       inputFileSize, outputFileSize, compressionRatio
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; 也顯示在訊息框中
    INVOKE wsprintfA, ADDR szMessageBuffer, ADDR szStatsFormat, 
           inputFileSize, outputFileSize, compressionRatio
    INVOKE MessageBoxA, hMainDialog, ADDR szMessageBuffer, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    
    ret
DisplayCompressionStats ENDP

;-----------------------------------------------
; 顯示解壓縮統計資訊
;-----------------------------------------------
DisplayDecompressionStats PROC
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szDecompStatsFormat, 
         outputFileSize, inputFileSize
    INVOKE UpdateStatus, ADDR szStatusBuffer
    ret
DisplayDecompressionStats ENDP

;-----------------------------------------------
; 選擇儲存檔案（壓縮用）
;-----------------------------------------------
SelectSaveFile PROC
    LOCAL ofn:OPENFILENAME
    
    ; 自動產生輸出檔名
    INVOKE GenerateOutputFilename, ADDR szInputFile, ADDR szOutputFile, ADDR hufExt
    
    ; 設定 OPENFILENAME 結構
    INVOKE SetupSaveFileStruct, ADDR ofn, ADDR szOutputFile, ADDR szFilterSave
    
    ; 顯示儲存檔案對話框
    INVOKE GetSaveFileNameA, ADDR ofn
    ret
SelectSaveFile ENDP

;-----------------------------------------------
; 顯示儲存檔案（解壓縮）
;-----------------------------------------------
SelectSaveFileDecompress PROC
    LOCAL ofn:OPENFILENAME
    
    ; 自動產生輸出檔名
    INVOKE GenerateOutputFilename, ADDR szInputFile, ADDR szOutputFile, ADDR txtExt

    ; 設定 OPENFILENAME 結構
    INVOKE SetupSaveFileStruct, ADDR ofn, ADDR szOutputFile, ADDR szFilterSave
    
    ; 顯示儲存檔案對話框
    INVOKE GetSaveFileNameA, ADDR ofn
    ret
SelectSaveFileDecompress ENDP

;-----------------------------------------------
; 產生輸出檔名
;-----------------------------------------------
GenerateOutputFilename PROC USES esi edi, pszInput:PTR BYTE, pszOutput:PTR BYTE, pszExtension:PTR BYTE
    LOCAL lastDotPos:DWORD
    
    mov esi, pszInput
    mov edi, pszOutput
    mov lastDotPos, 0
    
    ; 複製檔名並找到最後一個點的位置
    xor ecx, ecx
copy_filename:
    lodsb
    cmp al, 0
    je copy_done
    cmp al, '.'
    jne not_dot
    mov lastDotPos, ecx
not_dot:
    stosb
    inc ecx
    jmp copy_filename
    
copy_done:
    ; 如果找到點，回到那個位置
    .IF lastDotPos != 0
        mov edi, pszOutput
        add edi, lastDotPos
    .ENDIF
 
    ; 附加新副檔名
    mov esi, pszExtension
append_ext:
    lodsb
    stosb
    cmp al, 0
    jne append_ext
    
    ret
GenerateOutputFilename ENDP

;-----------------------------------------------
; 設定儲存檔案結構
;-----------------------------------------------
SetupSaveFileStruct PROC USES ebx, pOfn:PTR OPENFILENAME, pFile:PTR BYTE, pFilter:PTR BYTE
    mov ebx, pOfn
    
    mov eax, SIZEOF OPENFILENAME
    mov (OPENFILENAME PTR [ebx]).lStructSize, eax
    mov eax, hMainDialog
    mov (OPENFILENAME PTR [ebx]).hwndOwner, eax
    mov eax, hInstance
    mov (OPENFILENAME PTR [ebx]).hInstance, eax
    mov eax, pFilter
    mov (OPENFILENAME PTR [ebx]).lpstrFilter, eax
    mov (OPENFILENAME PTR [ebx]).lpstrCustomFilter, NULL
    mov (OPENFILENAME PTR [ebx]).nMaxCustFilter, 0
    mov (OPENFILENAME PTR [ebx]).nFilterIndex, 1
    mov eax, pFile
    mov (OPENFILENAME PTR [ebx]).lpstrFile, eax
    mov (OPENFILENAME PTR [ebx]).nMaxFile, 260
    mov (OPENFILENAME PTR [ebx]).lpstrFileTitle, NULL
  mov (OPENFILENAME PTR [ebx]).nMaxFileTitle, 0
    mov (OPENFILENAME PTR [ebx]).lpstrInitialDir, NULL
    mov eax, OFFSET szSaveTitle
    mov (OPENFILENAME PTR [ebx]).lpstrTitle, eax
    mov (OPENFILENAME PTR [ebx]).Flags, OFN_OVERWRITEPROMPT OR OFN_PATHMUSTEXIST
    mov (OPENFILENAME PTR [ebx]).nFileOffset, 0
    mov (OPENFILENAME PTR [ebx]).nFileExtension, 0
    mov (OPENFILENAME PTR [ebx]).lpstrDefExt, NULL
    mov (OPENFILENAME PTR [ebx]).lCustData, 0
  mov (OPENFILENAME PTR [ebx]).lpfnHook, NULL
    mov (OPENFILENAME PTR [ebx]).lpTemplateName, NULL
    
    ret
SetupSaveFileStruct ENDP

;-----------------------------------------------
; 清空緩衝區
;-----------------------------------------------
ClearBuffer PROC, pBuffer:PTR BYTE, bufSize:DWORD
    push edi
    push ecx
    mov edi, pBuffer
    mov ecx, bufSize
    xor al, al
    rep stosb
    pop ecx
    pop edi
    ret
ClearBuffer ENDP

;-----------------------------------------------
; 更新狀態訊息
;-----------------------------------------------
UpdateStatus PROC USES eax, pszMessage:PTR BYTE
    INVOKE GetDlgItem, hMainDialog, IDC_EDIT_STATUS
    INVOKE SetWindowTextA, eax, pszMessage
    ret
UpdateStatus ENDP

;-----------------------------------------------
; 取得壓縮檔案大小（供外部呼叫）
;-----------------------------------------------
GetCompressedFileSize PROC, pszFilePath:PTR BYTE
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    
    INVOKE OpenFileForRead, pszFilePath
    .IF eax == INVALID_HANDLE_VALUE
        xor eax, eax
        ret
    .ENDIF
    mov hFile, eax
    
    INVOKE GetFileSize, hFile, NULL
  mov fileSize, eax
    
    INVOKE CloseHandle, hFile
    mov eax, fileSize
    ret
GetCompressedFileSize ENDP

;===============================================
; 以下是公用 I/O 函式，供其他組員使用
;===============================================

;-----------------------------------------------
; OpenFileForRead
;-----------------------------------------------
OpenFileForRead PROC, pszFilePath:PTR BYTE
    INVOKE CreateFileA, pszFilePath, GENERIC_READ, 0, NULL, 
   OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    ret
OpenFileForRead ENDP

;-----------------------------------------------
; OpenFileForWrite
;-----------------------------------------------
OpenFileForWrite PROC, pszFilePath:PTR BYTE
    INVOKE CreateFileA, pszFilePath, GENERIC_WRITE, 0, NULL,
           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    ret
OpenFileForWrite ENDP

;-----------------------------------------------
; ReadFileByte
;-----------------------------------------------
ReadFileByte PROC USES ebx ecx edx, hFile:DWORD
    LOCAL buffer:BYTE
    LOCAL bytesRead:DWORD
    
    INVOKE ReadFile, hFile, ADDR buffer, 1, ADDR bytesRead, NULL
    .IF eax == 0
        mov eax, -1
        ret
    .ENDIF
    
    .IF bytesRead == 0
        mov eax, -1
        ret
    .ENDIF
    
    movzx eax, buffer
    ret
ReadFileByte ENDP

;-----------------------------------------------
; WriteFileByte
;-----------------------------------------------
WriteFileByte PROC USES ebx ecx edx, hFile:DWORD, byteVal:BYTE
    LOCAL bytesWritten:DWORD
    
    INVOKE WriteFile, hFile, ADDR byteVal, 1, ADDR bytesWritten, NULL
 ret
WriteFileByte ENDP

;-----------------------------------------------
; ReadFileBuffer
;-----------------------------------------------
ReadFileBuffer PROC, hFile:DWORD, pBuffer:PTR BYTE, nBytes:DWORD
    LOCAL bytesRead:DWORD
  
    INVOKE ReadFile, hFile, pBuffer, nBytes, ADDR bytesRead, NULL
    .IF eax == 0
        mov eax, 0
      ret
    .ENDIF
    
    mov eax, bytesRead
    ret
ReadFileBuffer ENDP

;-----------------------------------------------
; WriteFileBuffer
;-----------------------------------------------
WriteFileBuffer PROC, hFile:DWORD, pBuffer:PTR BYTE, nBytes:DWORD
    LOCAL bytesWritten:DWORD
    
    INVOKE WriteFile, hFile, pBuffer, nBytes, ADDR bytesWritten, NULL
    .IF eax == 0
 mov eax, 0
     ret
.ENDIF
    
    mov eax, bytesWritten
    ret
WriteFileBuffer ENDP

;-----------------------------------------------
; CloseFileHandle
;-----------------------------------------------
CloseFileHandle PROC, hFile:DWORD
    INVOKE CloseHandle, hFile
    ret
CloseFileHandle ENDP

;-----------------------------------------------
; GetFileSizeEx
;-----------------------------------------------
GetFileSizeEx PROC, hFile:DWORD
    INVOKE GetFileSize, hFile, NULL
    ret
GetFileSizeEx ENDP

;-----------------------------------------------
; SeekFile
;-----------------------------------------------
SeekFile PROC, hFile:DWORD, distanceToMove:SDWORD, moveMethod:DWORD
    INVOKE SetFilePointer, hFile, distanceToMove, NULL, moveMethod
    ret
SeekFile ENDP

;===============================================
; 新增：額外的工具函式
;===============================================

;-----------------------------------------------
; CopyFile - 複製檔案（供測試使用）
; 參數：pszSource, pszDest
; 傳回：EAX = 1 (成功) 或 0 (失敗)
;-----------------------------------------------
CopyFileData PROC USES ebx esi edi, pszSource:PTR BYTE, pszDest:PTR BYTE
    LOCAL hFileIn:DWORD
    LOCAL hFileOut:DWORD
    LOCAL buffer[4096]:BYTE
    LOCAL bytesRead:DWORD
    
    ; 開啟來源檔案
    INVOKE OpenFileForRead, pszSource
    .IF eax == INVALID_HANDLE_VALUE
        xor eax, eax
        ret
    .ENDIF
    mov hFileIn, eax

    ; 開啟目的檔案
INVOKE OpenFileForWrite, pszDest
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE CloseFileHandle, hFileIn
        xor eax, eax
        ret
    .ENDIF
    mov hFileOut, eax
    
    ; 複製資料
copy_loop:
    INVOKE ReadFileBuffer, hFileIn, ADDR buffer, 4096
    mov bytesRead, eax
    .IF eax == 0
        jmp copy_done
    .ENDIF
    
    INVOKE WriteFileBuffer, hFileOut, ADDR buffer, bytesRead
    .IF eax != bytesRead
        ; 寫入錯誤
        INVOKE CloseFileHandle, hFileIn
   INVOKE CloseFileHandle, hFileOut
        xor eax, eax
        ret
    .ENDIF
    
    jmp copy_loop
    
copy_done:
    INVOKE CloseFileHandle, hFileIn
    INVOKE CloseFileHandle, hFileOut
    mov eax, 1
    ret
CopyFileData ENDP

;-----------------------------------------------
; CompareFiles - 比較兩個檔案是否相同
; 參數：pszFile1, pszFile2
; 傳回：EAX = 1 (相同) 或 0 (不同/錯誤)
;-----------------------------------------------
CompareFiles PROC USES ebx esi edi, pszFile1:PTR BYTE, pszFile2:PTR BYTE
    LOCAL hFile1:DWORD
    LOCAL hFile2:DWORD
    LOCAL buffer1[1024]:BYTE
    LOCAL buffer2[1024]:BYTE
    LOCAL bytesRead1:DWORD
    LOCAL bytesRead2:DWORD
    
    ; 開啟檔案 1
    INVOKE OpenFileForRead, pszFile1
    .IF eax == INVALID_HANDLE_VALUE
        xor eax, eax
        ret
    .ENDIF
    mov hFile1, eax
    
    ; 開啟檔案 2
    INVOKE OpenFileForRead, pszFile2
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE CloseFileHandle, hFile1
  xor eax, eax
        ret
    .ENDIF
    mov hFile2, eax
    
    ; 比較檔案大小
    INVOKE GetFileSizeEx, hFile1
    mov ebx, eax
    INVOKE GetFileSizeEx, hFile2
    .IF eax != ebx
        ; 大小不同
        INVOKE CloseFileHandle, hFile1
        INVOKE CloseFileHandle, hFile2
        xor eax, eax
        ret
    .ENDIF
    
    ; 逐塊比較
compare_loop:
    INVOKE ReadFileBuffer, hFile1, ADDR buffer1, 1024
    mov bytesRead1, eax
    INVOKE ReadFileBuffer, hFile2, ADDR buffer2, 1024
    mov bytesRead2, eax
 
    ; 檢查讀取數量
    mov eax, bytesRead1
    mov ebx, bytesRead2
    .IF eax != ebx
        INVOKE CloseFileHandle, hFile1
        INVOKE CloseFileHandle, hFile2
        xor eax, eax
      ret
    .ENDIF
    
 ; 如果都讀完了
    .IF bytesRead1 == 0
     jmp compare_success
    .ENDIF
    
    ; 比較緩衝區
    lea esi, buffer1
    lea edi, buffer2
    mov ecx, bytesRead1
    repe cmpsb
    .IF !ZERO?
        ; 不相同
   INVOKE CloseFileHandle, hFile1
        INVOKE CloseFileHandle, hFile2
        xor eax, eax
    ret
    .ENDIF
    
 jmp compare_loop
    
compare_success:
    INVOKE CloseFileHandle, hFile1
    INVOKE CloseFileHandle, hFile2
    mov eax, 1
 ret
CompareFiles ENDP

END main
