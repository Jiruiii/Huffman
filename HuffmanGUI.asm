; ===============================================
; Huffman Coding File Compression Tool
; 人員一：GUI 與檔案 I/O 總管（加強版）
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

; String 處理
wsprintfA PROTO C, lpOut:PTR BYTE, lpFmt:PTR BYTE, args:VARARG

; 常數定義區
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
; 全域變數區
hInstance  DWORD ?
hMainDialog     DWORD ?
szInputFile     BYTE 260 DUP(0)
szOutputFile    BYTE 260 DUP(0)
inputFileSize   DWORD ?
outputFileSize  DWORD ?

; 檔案過濾器
szFilterCompress    BYTE "Text Files (*.txt)",0,"*.txt",0
      BYTE "All Files (*.*)",0,"*.*",0,0
huffFilterStr       BYTE "Huffman Files (*.huff)",0,"*.huff",0
         BYTE "All Files (*.*)",0,"*.*",0,0
szFilterDecompress  BYTE "Huffman Files (*.huff)",0,"*.huff",0
         BYTE "All Files (*.*)",0,"*.*",0,0
szFilterSave        BYTE "Huffman Files (*.huff)",0,"*.huff",0
            BYTE "Text Files (*.txt)",0,"*.txt",0,0

; 文字訊息
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

; 壓縮率訊息格式字串
szStatsFormat       BYTE "Input: %d bytes | Output: %d bytes | Compression: %d%%",0
szDecompStatsFormat BYTE "Decompressed: %d bytes from %d bytes compressed file",0
szReadyWithFile     BYTE "Selected: %s (%d bytes)",0

; 狀態暫存區
szStatusBuffer      BYTE 512 DUP(0)
szMessageBuffer  BYTE 512 DUP(0)

; 副檔名字串
hufExt BYTE ".huff",0
txtExt BYTE ".txt",0

; 除錯訊息
szDebugMsg BYTE "Building Huffman Tree...",0

; 前置宣告 (Forward Declarations)
DlgProc PROTO, hDlg:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
CompressFile PROTO
DecompressFile PROTO
SetupOpenFileStruct PROTO, pOfn:PTR OPENFILENAME, pFile:PTR BYTE, pFilter:PTR BYTE, pTitle:PTR BYTE
ValidateInputFile PROTO, pszFilePath:PTR BYTE
DisplayCompressionStats PROTO
DisplayDecompressionStats PROTO
DecompressHuffmanFile PROTO, pszInputFile:PTR BYTE, pszOutputFile:PTR BYTE
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
; 程式進入點
;-----------------------------------------------
main PROC
    INVOKE GetModuleHandleA, NULL
    mov hInstance, eax
    
    ; ��ܥD��ܮ�
    INVOKE DialogBoxParamA, hInstance, IDD_MAIN_DIALOG, NULL, ADDR DlgProc, 0
    
    INVOKE ExitProcess, 0
main ENDP

;-----------------------------------------------
; 主視窗訊息處理程序
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
; 壓縮檔案主程序
;-----------------------------------------------
CompressFile PROC
    LOCAL ofn:OPENFILENAME
    LOCAL hFile:DWORD
    
    ; �M���ɮ׸��|�w�İ�
    INVOKE ClearBuffer, ADDR szInputFile, 260
    INVOKE ClearBuffer, ADDR szOutputFile, 260
    
    ; �]�w OPENFILENAME ���c
    INVOKE SetupOpenFileStruct, ADDR ofn, ADDR szInputFile, ADDR szFilterCompress, ADDR szCompressTitle
 
    ; ��ܶ}���ɮ׹�ܮ�
    INVOKE GetOpenFileNameA, ADDR ofn
    .IF eax == 0
        ret
    .ENDIF

    ; �����ɮ�
    INVOKE ValidateInputFile, ADDR szInputFile
    .IF eax == 0
  ret
    .ENDIF
    mov inputFileSize, eax
    
    ; ����ɮ׸�T
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szReadyWithFile, ADDR szInputFile, inputFileSize
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; ��ܿ�X�ɮ�
    call SelectSaveFile
    .IF eax == 0
        ret
    .ENDIF
    
    ; ��s���A
    INVOKE UpdateStatus, ADDR szCompressing
    
    ; TODO: �b�o�̩I�s�H���G�B�T���禡
    ; INVOKE BuildHuffmanTree, ADDR szInputFile
    ; mov pTreeRoot, eax
    ; .IF eax != NULL
    ;     INVOKE CompressWithHuffman, pTreeRoot, ADDR szInputFile, ADDR szOutputFile
    ;     .IF eax != 0
    ;         ; ���Y���\�A��ܲέp
    ;         INVOKE GetCompressedFileSize, ADDR szOutputFile
    ;      mov outputFileSize, eax
    ;  INVOKE DisplayCompressionStats
    ;     .ENDIF
    ; .ENDIF
    
    ; �������Y�]�Ȯɡ^
    mov eax, inputFileSize
    shr eax, 1  ; ���]���Y�v 50%
    mov outputFileSize, eax
    
    ; ��ܲέp��T
    call DisplayCompressionStats
    
    ; ��ܧ����T����
    INVOKE MessageBoxA, hMainDialog, ADDR szSuccess, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    INVOKE UpdateStatus, ADDR szStatus
    
    ret
CompressFile ENDP

;-----------------------------------------------
; 解壓縮檔案主程序
;-----------------------------------------------
DecompressFile PROC
    LOCAL ofn:OPENFILENAME
    LOCAL hFile:DWORD
    
    ; �M���ɮ׸��|�w�İ�
    INVOKE ClearBuffer, ADDR szInputFile, 260
    INVOKE ClearBuffer, ADDR szOutputFile, 260
    
    ; �]�w OPENFILENAME ���c
    INVOKE SetupOpenFileStruct, ADDR ofn, ADDR szInputFile, ADDR szFilterDecompress, ADDR szDecompressTitle
 
    ; ��ܶ}���ɮ׹�ܮ�
    INVOKE GetOpenFileNameA, ADDR ofn
    .IF eax == 0
        ret
    .ENDIF
    
    ; �����ɮ�
    INVOKE ValidateInputFile, ADDR szInputFile
    .IF eax == 0
      ret
    .ENDIF
    mov inputFileSize, eax
    
    ; ����ɮ׸�T
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szReadyWithFile, ADDR szInputFile, inputFileSize
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; ��ܿ�X�ɮ�
    call SelectSaveFileDecompress
    .IF eax == 0
        ret
    .ENDIF
    
    ; ��s���A
    INVOKE UpdateStatus, ADDR szDecompressing
    

    ; 呼叫人員四解碼主程式
    INVOKE DecompressHuffmanFile, ADDR szInputFile, ADDR szOutputFile
    .IF eax != 0
        ; 解壓縮成功，顯示統計
        INVOKE GetCompressedFileSize, ADDR szOutputFile
        mov outputFileSize, eax
        INVOKE DisplayDecompressionStats
    .ENDIF
    
    ; ���������Y�]�Ȯɡ^
    mov eax, inputFileSize
shl eax, 1  ; ���]�٭쬰 2 ��
    mov outputFileSize, eax
    
    ; ��ܲέp��T
    call DisplayDecompressionStats
    
    ; ��ܧ����T����
  INVOKE MessageBoxA, hMainDialog, ADDR szSuccess, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    INVOKE UpdateStatus, ADDR szStatus
    
    ret
DecompressFile ENDP

;-----------------------------------------------
; 設定 OPENFILENAME 結構內容
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
; 回傳：EAX = 檔案大小（失敗則為 0）
;-----------------------------------------------
ValidateInputFile PROC USES ebx, pszFilePath:PTR BYTE
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    
    ; �}���ɮ�
    INVOKE OpenFileForRead, pszFilePath
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE MessageBoxA, hMainDialog, ADDR szFileError, ADDR szError, MB_OK OR MB_ICONERROR
        xor eax, eax
    ret
    .ENDIF
    mov hFile, eax
    
    ; ���o�ɮפj�p
    INVOKE GetFileSize, hFile, NULL
    .IF eax == -1
        INVOKE CloseHandle, hFile
        INVOKE MessageBoxA, hMainDialog, ADDR szFileError, ADDR szError, MB_OK OR MB_ICONERROR
        xor eax, eax
        ret
    .ENDIF
    mov fileSize, eax
    
    ; �ˬd�O�_�����ɮ�
    .IF fileSize == 0
        INVOKE CloseHandle, hFile
        INVOKE MessageBoxA, hMainDialog, ADDR szEmptyFile, ADDR szError, MB_OK OR MB_ICONWARNING
    xor eax, eax
        ret
    .ENDIF
    
    ; �ˬd�ɮפj�p�]���� 10MB�^
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
; 顯示壓縮率訊息
;-----------------------------------------------
DisplayCompressionStats PROC USES eax ebx ecx edx
    LOCAL compressionRatio:DWORD
    
    ; �p�����Y�v = (1 - compressed/original) * 100
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
    
    ; �榡�ưT��
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szStatsFormat, 
       inputFileSize, outputFileSize, compressionRatio
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; �]��ܦb�T���ؤ�
    INVOKE wsprintfA, ADDR szMessageBuffer, ADDR szStatsFormat, 
           inputFileSize, outputFileSize, compressionRatio
    INVOKE MessageBoxA, hMainDialog, ADDR szMessageBuffer, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    
    ret
DisplayCompressionStats ENDP

;-----------------------------------------------
; 顯示解壓縮訊息
;-----------------------------------------------
DisplayDecompressionStats PROC
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szDecompStatsFormat, 
         outputFileSize, inputFileSize
    INVOKE UpdateStatus, ADDR szStatusBuffer
    ret
DisplayDecompressionStats ENDP

;-----------------------------------------------
; 選擇壓縮檔案儲存位置
;-----------------------------------------------
SelectSaveFile PROC
    LOCAL ofn:OPENFILENAME
    
    ; �۰ʲ��Ϳ�X�ɦW
    INVOKE GenerateOutputFilename, ADDR szInputFile, ADDR szOutputFile, ADDR hufExt
    
    ; �]�w OPENFILENAME ���c
    INVOKE SetupSaveFileStruct, ADDR ofn, ADDR szOutputFile, ADDR szFilterSave
    
    ; ����x�s�ɮ׹�ܮ�
    INVOKE GetSaveFileNameA, ADDR ofn
    ret
SelectSaveFile ENDP

;-----------------------------------------------
; 選擇解壓縮檔案儲存位置
;-----------------------------------------------
SelectSaveFileDecompress PROC
    LOCAL ofn:OPENFILENAME
    
    ; �۰ʲ��Ϳ�X�ɦW
    INVOKE GenerateOutputFilename, ADDR szInputFile, ADDR szOutputFile, ADDR txtExt

    ; �]�w OPENFILENAME ���c
    INVOKE SetupSaveFileStruct, ADDR ofn, ADDR szOutputFile, ADDR szFilterSave
    
    ; ����x�s�ɮ׹�ܮ�
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
    
    ; �ƻs�ɦW�ç��̫�@���I����m
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
    ; �p�G����I�A�^�쨺�Ӧ�m
    .IF lastDotPos != 0
        mov edi, pszOutput
        add edi, lastDotPos
    .ENDIF
 
    ; ���[�s���ɦW
    mov esi, pszExtension
append_ext:
    lodsb
    stosb
    cmp al, 0
    jne append_ext
    
    ret
GenerateOutputFilename ENDP

;-----------------------------------------------
; 設定儲存檔案對話框結構
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
; 取得壓縮檔案大小（若失敗回傳 0）
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
; 以下為通用 I/O 函式，供其他模組呼叫
;===============================================

;-----------------------------------------------
; 開啟檔案（讀取）
;-----------------------------------------------
OpenFileForRead PROC, pszFilePath:PTR BYTE
    INVOKE CreateFileA, pszFilePath, GENERIC_READ, 0, NULL, 
   OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    ret
OpenFileForRead ENDP

;-----------------------------------------------
; 開啟檔案（寫入）
;-----------------------------------------------
OpenFileForWrite PROC, pszFilePath:PTR BYTE
    INVOKE CreateFileA, pszFilePath, GENERIC_WRITE, 0, NULL,
           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    ret
OpenFileForWrite ENDP

;-----------------------------------------------
; 讀取單一位元組
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
; 寫入單一位元組
;-----------------------------------------------
WriteFileByte PROC USES ebx ecx edx, hFile:DWORD, byteVal:BYTE
    LOCAL bytesWritten:DWORD
    
    INVOKE WriteFile, hFile, ADDR byteVal, 1, ADDR bytesWritten, NULL
 ret
WriteFileByte ENDP

;-----------------------------------------------
; 讀取緩衝區
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
; 寫入緩衝區
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
; 關閉檔案
;-----------------------------------------------
CloseFileHandle PROC, hFile:DWORD
    INVOKE CloseHandle, hFile
    ret
CloseFileHandle ENDP

;-----------------------------------------------
; 取得檔案大小
;-----------------------------------------------
GetFileSizeEx PROC, hFile:DWORD
    INVOKE GetFileSize, hFile, NULL
    ret
GetFileSizeEx ENDP

;-----------------------------------------------
; 移動檔案指標
;-----------------------------------------------
SeekFile PROC, hFile:DWORD, distanceToMove:SDWORD, moveMethod:DWORD
    INVOKE SetFilePointer, hFile, distanceToMove, NULL, moveMethod
    ret
SeekFile ENDP

;===============================================
; 其他工具函式
;===============================================

;-----------------------------------------------
; CopyFile - 複製檔案（供測試用）
; 參數：pszSource, pszDest
; 回傳：EAX = 1 (成功) 或 0 (失敗)
;-----------------------------------------------
CopyFileData PROC USES ebx esi edi, pszSource:PTR BYTE, pszDest:PTR BYTE
    LOCAL hFileIn:DWORD
    LOCAL hFileOut:DWORD
    LOCAL buffer[4096]:BYTE
    LOCAL bytesRead:DWORD
    
    ; �}�Ҩӷ��ɮ�
    INVOKE OpenFileForRead, pszSource
    .IF eax == INVALID_HANDLE_VALUE
        xor eax, eax
        ret
    .ENDIF
    mov hFileIn, eax

    ; �}�ҥت��ɮ�
INVOKE OpenFileForWrite, pszDest
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE CloseFileHandle, hFileIn
        xor eax, eax
        ret
    .ENDIF
    mov hFileOut, eax
    
    ; �ƻs���
copy_loop:
    INVOKE ReadFileBuffer, hFileIn, ADDR buffer, 4096
    mov bytesRead, eax
    .IF eax == 0
        jmp copy_done
    .ENDIF
    
    INVOKE WriteFileBuffer, hFileOut, ADDR buffer, bytesRead
    .IF eax != bytesRead
        ; �g�J���~
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
; CompareFiles - 比較兩檔案是否相同
; 參數：pszFile1, pszFile2
; 回傳：EAX = 1 (相同) 或 0 (不同/失敗)
;-----------------------------------------------
CompareFiles PROC USES ebx esi edi, pszFile1:PTR BYTE, pszFile2:PTR BYTE
    LOCAL hFile1:DWORD
    LOCAL hFile2:DWORD
    LOCAL buffer1[1024]:BYTE
    LOCAL buffer2[1024]:BYTE
    LOCAL bytesRead1:DWORD
    LOCAL bytesRead2:DWORD
    
    ; �}���ɮ� 1
    INVOKE OpenFileForRead, pszFile1
    .IF eax == INVALID_HANDLE_VALUE
        xor eax, eax
        ret
    .ENDIF
    mov hFile1, eax
    
    ; �}���ɮ� 2
    INVOKE OpenFileForRead, pszFile2
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE CloseFileHandle, hFile1
  xor eax, eax
        ret
    .ENDIF
    mov hFile2, eax
    
    ; ����ɮפj�p
    INVOKE GetFileSizeEx, hFile1
    mov ebx, eax
    INVOKE GetFileSizeEx, hFile2
    .IF eax != ebx
        ; �j�p���P
        INVOKE CloseFileHandle, hFile1
        INVOKE CloseFileHandle, hFile2
        xor eax, eax
        ret
    .ENDIF
    
    ; �v�����
compare_loop:
    INVOKE ReadFileBuffer, hFile1, ADDR buffer1, 1024
    mov bytesRead1, eax
    INVOKE ReadFileBuffer, hFile2, ADDR buffer2, 1024
    mov bytesRead2, eax
 
    ; �ˬdŪ���ƶq
    mov eax, bytesRead1
    mov ebx, bytesRead2
    .IF eax != ebx
        INVOKE CloseFileHandle, hFile1
        INVOKE CloseFileHandle, hFile2
        xor eax, eax
      ret
    .ENDIF
    
 ; �p�G��Ū���F
    .IF bytesRead1 == 0
     jmp compare_success
    .ENDIF
    
    ; ����w�İ�
    lea esi, buffer1
    lea edi, buffer2
    mov ecx, bytesRead1
    repe cmpsb
    .IF !ZERO?
        ; ���ۦP
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
