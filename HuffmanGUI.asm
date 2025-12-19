.386
.model flat, stdcall
option casemap :none

INCLUDE Irvine32.inc
INCLUDE macros.inc

; Windows API å®??
GetModuleHandleA PROTO, lpModuleName:PTR BYTE
DialogBoxParamA PROTO, hInstance:DWORD, lpTemplateName:DWORD, hWndParent:DWORD, lpDialogFunc:DWORD, dwInitParam:DWORD
EndDialog PROTO, hDlg:DWORD, nResult:DWORD
GetDlgItem PROTO, hDlg:DWORD, nIDDlgItem:DWORD
SetWindowTextA PROTO, hWnd:DWORD, lpString:PTR BYTE
GetOpenFileNameA PROTO, lpofn:PTR OPENFILENAME
GetSaveFileNameA PROTO, lpofn:PTR OPENFILENAME
DragQueryFileA PROTO, hDrop:DWORD, iFile:DWORD, lpszFile:PTR BYTE, cch:DWORD
DragFinish PROTO, hDrop:DWORD
DragAcceptFiles PROTO, hWnd:DWORD, fAccept:DWORD
SendMessageA PROTO, hWnd:DWORD, Msg:DWORD, wParam:DWORD, lParam:DWORD

; æª”æ? I/O API
CreateFileA PROTO, lpFileName:PTR BYTE, dwDesiredAccess:DWORD, dwShareMode:DWORD,
    lpSecurityAttributes:DWORD, dwCreationDisposition:DWORD, dwFlagsAndAttributes:DWORD, hTemplateFile:DWORD
; ReadFile and WriteFile are already defined in Windows libraries
CloseHandle PROTO, hObject:DWORD
GetFileSize PROTO, hFile:DWORD, lpFileSizeHigh:DWORD
; SetFilePointer is already defined in Windows libraries
MessageBoxA PROTO, hWnd:DWORD, lpText:PTR BYTE, lpCaption:PTR BYTE, uType:DWORD

; String ¨ç¦¡
wsprintfA PROTO C, lpOut:PTR BYTE, lpFmt:PTR BYTE, args:VARARG

; ¥~³¡¨ç¼Æ­ì«¬¡]¨Ó¦Û¤H­û¤G¡B¤T¡B¥|ªº¼Ò²Õ¡^
Pro2_CompressFile PROTO, pszInputFile:PTR BYTE, pszOutputFile:PTR BYTE
DecompressHuffmanFile PROTO, pszInputFile:PTR BYTE, pszOutputFile:PTR BYTE

; ¾É¥X¤½¥Î¨ç¼Æ¨Ñ¨ä¥L¼Ò²Õ¨Ï¥Î

; å°Žå‡º?¬ç”¨?½æ•¸ä¾›å…¶ä»–æ¨¡çµ„ä½¿??
PUBLIC OpenFileForRead
PUBLIC OpenFileForWrite
PUBLIC ReadFileByte
PUBLIC WriteFileByte
PUBLIC ReadFileBuffer
PUBLIC WriteFileBuffer
PUBLIC CloseFileHandle
PUBLIC GetFileSizeEx
PUBLIC SeekFile

; å¸¸æ•¸å®šç¾©?€
.const
IDD_MAIN_DIALOG  EQU 101
IDC_BTN_COMPRESS    EQU 1001
IDC_BTN_DECOMPRESS  EQU 1002
IDC_EDIT_STATUS     EQU 1003
IDC_BTN_EXIT        EQU 1004
IDC_PROGRESS_BAR    EQU 1005

WM_INITDIALOG       EQU 0110h
WM_COMMAND        EQU 0111h
WM_CLOSE            EQU 0010h
WM_DROPFILES        EQU 0233h

; Progress Bar Messages
PBM_SETRANGE        EQU 0401h
PBM_SETPOS          EQU 0402h
PBM_DELTAPOS        EQU 0403h
PBM_SETSTEP         EQU 0404h
PBM_STEPIT          EQU 0405h

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
OFN_EXPLORER        EQU 80000h
OFN_ALLOWMULTISELECT EQU 200h

MB_OK          EQU 0
MB_ICONINFORMATION  EQU 40h
MB_ICONERROR        EQU 10h
MB_ICONWARNING    EQU 30h

; OPENFILENAME çµæ?
OPENFILENAME STRUCT
    lStructSize       DWORD ? 
    hwndOwner         DWORD ?
    hInstance         DWORD ?
    lpstrFilter       DWORD ?
    lpstrCustomFilter DWORD ?
    nMaxCustFilter    DWORD ?
    nFilterIndex      DWORD ?
    lpstrFile         DWORD ?
    nMaxFile          DWORD ?
    lpstrFileTitle    DWORD ?
    nMaxFileTitle     DWORD ?
    lpstrInitialDir   DWORD ?
    lpstrTitle        DWORD ?
    Flags             DWORD ?
    nFileOffset       WORD  ?
    nFileExtension    WORD  ?
    lpstrDefExt       DWORD ?
    lCustData         DWORD ?
    lpfnHook          DWORD ?
    lpTemplateName    DWORD ?
OPENFILENAME ENDS

.data
; ?¨å?è®Šæ•¸?€
hInstance  DWORD ?
hMainDialog     DWORD ?
hProgressBar    DWORD ?
szInputFile     BYTE 260 DUP(0)
szOutputFile    BYTE 260 DUP(0)
inputFileSize   DWORD ?
outputFileSize  DWORD ?

; §å¦¸³B²zÅÜ¼Æ
szBatchFiles    BYTE 65536 DUP(0)  ; Àx¦s¦h­ÓÀÉ®×¸ô®|¡]¨C­Ó³Ì¦h 260 bytes¡^
batchFileCount  DWORD 0
currentFileIndex DWORD 0

; ¥Î©ó RebuildFullPathsFromDialog ªº¤u§@½w½Ä°Ï
tempDirPath     BYTE 260 DUP(0)
tempFilePath    BYTE 260 DUP(0)
tempFileList    BYTE 2600 DUP(0)  ; 10­ÓÀÉ®× * 260¦r¸`

; æª”æ??Žæ¿¾??
szFilterCompress    BYTE "Text Files (*.txt)",0,"*.txt",0
      BYTE "All Files (*.*)",0,"*.*",0,0
huffFilterStr       BYTE "Huffman Files (*.huff)",0,"*.huff",0
         BYTE "All Files (*.*)",0,"*.*",0,0
szFilterDecompress  BYTE "Huffman Files (*.huff)",0,"*.huff",0
         BYTE "All Files (*.*)",0,"*.*",0,0
szFilterSave        BYTE "Huffman Files (*.huff)",0,"*.huff",0
            BYTE "Text Files (*.txt)",0,"*.txt",0,0

; ?‡å?è¨Šæ¯
szAppTitle  BYTE "Huffman File Compressor v2.0",0
szCompressTitle     BYTE "Select File(s) to Compress",0
szDecompressTitle   BYTE "Select File(s) to Decompress",0
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
szBatchProcessing   BYTE "Processing file %d of %d...",0
szBatchComplete     BYTE "Batch processing completed! %d files processed.",0

; å£“ç¸®?‡è??¯æ ¼å¼å?ä¸?
szStatsFormat       BYTE "Input: %d bytes | Output: %d bytes | Compression: %d%%",0
szDecompStatsFormat BYTE "Decompressed: %d bytes from %d bytes compressed file",0
szReadyWithFile     BYTE "Selected: %s (%d bytes)",0

; ?€?‹æš«å­˜å?
szStatusBuffer      BYTE 512 DUP(0)
szMessageBuffer  BYTE 512 DUP(0)

; ?¯æ??å?ä¸?
hufExt BYTE ".huff",0
txtExt BYTE ".txt",0

; ?¤éŒ¯è¨Šæ¯
szDebugMsg BYTE "Building Huffman Tree...",0

; ?ç½®å®?? (Forward Declarations)
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
UpdateProgress PROTO, position:DWORD, maxValue:DWORD
ResetProgress PROTO
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
ProcessBatchCompress PROTO
ProcessBatchDecompress PROTO
RebuildFullPathsFromDialog PROTO
.code

; ================================================
; ç¨‹å??²å…¥é»?
;-----------------------------------------------
main PROC
    INVOKE GetModuleHandleA, NULL
    mov hInstance, eax
    
    ; DialogBoxParam with numeric resource ID
    INVOKE DialogBoxParamA, hInstance, 101, NULL, ADDR DlgProc, 0
    
    INVOKE ExitProcess, 0
main ENDP

;-----------------------------------------------
; ä¸»è?çª—è??¯è??†ç?åº?
;-----------------------------------------------
DlgProc PROC, hDlg:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    .IF uMsg == WM_INITDIALOG
        mov eax, hDlg
        mov hMainDialog, eax
        
        ; Enable drag & drop
        INVOKE DragAcceptFiles, hDlg, TRUE
        
        ; ªì©l¤Æª¬ºA¦C
        INVOKE GetDlgItem, hDlg, IDC_EDIT_STATUS
        INVOKE SetWindowTextA, eax, ADDR szStatus
        
        ; ªì©l¤Æ¶i«×±ø
        INVOKE GetDlgItem, hDlg, IDC_PROGRESS_BAR
        mov hProgressBar, eax
        INVOKE SendMessageA, hProgressBar, PBM_SETRANGE, 0, 100
        INVOKE SendMessageA, hProgressBar, PBM_SETPOS, 0, 0
        
        mov eax, TRUE
        ret
        
    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam
        and eax, 0FFFFh
        
        .IF eax == IDC_BTN_COMPRESS
            call CompressFile
            mov eax, TRUE
            ret
        .ELSEIF eax == IDC_BTN_DECOMPRESS
            call DecompressFile
            mov eax, TRUE
            ret
        .ELSEIF eax == IDC_BTN_EXIT
            INVOKE EndDialog, hDlg, 0
            mov eax, TRUE
            ret
        .ENDIF
        
    .ELSEIF uMsg == WM_DROPFILES
        ; Handle drag & drop - ¤ä´©¦hÀÉ®×
        push ebx
        push esi
        push edi
        mov ebx, wParam  ; hDrop handle
        
        ; ¨ú±o©ì©ñÀÉ®×¼Æ¶q
        INVOKE DragQueryFileA, ebx, 0FFFFFFFFh, 0, 0
        mov batchFileCount, eax
        
        .IF eax == 0
            INVOKE DragFinish, ebx
            pop edi
            pop esi
            pop ebx
            mov eax, TRUE
            ret
        .ENDIF
        
        ; ²MªÅ§å¦¸ÀÉ®×½w½Ä°Ï
        INVOKE ClearBuffer, ADDR szBatchFiles, 65536
        
        ; Åª¨ú©Ò¦³©ì©ñªºÀÉ®×¸ô®|
        xor esi, esi  ; ÀÉ®×¯Á¤Þ
        lea edi, szBatchFiles
        
read_dropped_files:
        cmp esi, batchFileCount
        jge dropped_files_done
        
        ; Åª¨ú²Ä i ­ÓÀÉ®×¸ô®|
        INVOKE DragQueryFileA, ebx, esi, edi, 260
        .IF eax != 0
            ; ²¾°Ê¨ì¤U¤@­ÓÀÉ®×¸ô®|¦ì¸m¡]¨C­Ó¸ô®|¦û 260 bytes¡^
            add edi, 260
            inc esi
            jmp read_dropped_files
        .ENDIF
        
dropped_files_done:
        INVOKE DragFinish, ebx
        
        ; §PÂ_¬OÀ£ÁYÁÙ¬O¸ÑÀ£ÁY¡]®Ú¾Ú²Ä¤@­ÓÀÉ®×ªº°ÆÀÉ¦W¡^
        lea esi, szBatchFiles
        
        ; ÀË¬d°ÆÀÉ¦W
        push esi
        xor ecx, ecx
find_ext_batch:
        mov al, [esi]
        .IF al == 0
            pop esi
            jmp check_extension_batch
        .ENDIF
        .IF al == '.'
            mov ecx, esi
        .ENDIF
        inc esi
        jmp find_ext_batch
        
check_extension_batch:
        .IF ecx != 0
            inc ecx
            mov al, [ecx]
            .IF al == 'h' || al == 'H'
                inc ecx
                mov al, [ecx]
                .IF al == 'u' || al == 'U'
                    ; .huff ÀÉ®× -> §å¦¸¸ÑÀ£ÁY
                    call ProcessBatchDecompress
                    pop edi
                    pop esi
                    pop ebx
                    mov eax, TRUE
                    ret
                .ENDIF
            .ENDIF
        .ENDIF
        
        ; ¹w³]¡G§å¦¸À£ÁY
        call ProcessBatchCompress
        
        pop edi
        pop esi
        pop ebx
        mov eax, TRUE
        ret
        
    .ELSEIF uMsg == WM_CLOSE
        INVOKE EndDialog, hDlg, 0
    .ENDIF
    
    mov eax, FALSE
    ret
DlgProc ENDP

;-----------------------------------------------
; ïÌæª?æµ?ï¼?å¼·ç?ï¼?
;-----------------------------------------------
CompressFile PROC
LOCAL ofn:OPENFILENAME
    LOCAL hFile:DWORD
    LOCAL skipDialog:DWORD
    
    ; Check if szInputFile is already set (from drag & drop)
    mov skipDialog, 0
    mov al, szInputFile[0]
    .IF al != 0
        ; File already selected via drag & drop
        mov skipDialog, 1
    .ELSE
        ; Clear file path buffers
        INVOKE ClearBuffer, ADDR szInputFile, 260
        INVOKE ClearBuffer, ADDR szBatchFiles, 65536
    .ENDIF
    
    INVOKE ClearBuffer, ADDR szOutputFile, 260
    
    .IF skipDialog == 0
        ; ¥ý²MªÅ szBatchFiles ½w½Ä°Ï¡]½T«O¦h¿ï¥¿±`¹B§@¡^
        INVOKE ClearBuffer, ADDR szBatchFiles, 65536
        
        ; ³]©w OPENFILENAME µ²ºc¡]¤ä´©¦hÀÉ®×¿ï¾Ü¡^
        INVOKE SetupOpenFileStruct, ADDR ofn, ADDR szBatchFiles, ADDR szFilterCompress, ADDR szCompressTitle
     
        ; Åã¥Ü¿ï¾ÜÀÉ®×¹ï¸Ü®Ø
        INVOKE GetOpenFileNameA, ADDR ofn
        .IF eax == 0
            ret
        .ENDIF

        ; ¸ÑªR¦hÀÉ®×¿ï¾Üµ²ªG
        ; ®æ¦¡¡Gdirectory\0file1\0file2\0\0
        lea esi, szBatchFiles
        
        ; ÀË¬d¬O³æÀÉÁÙ¬O¦hÀÉ
        ; §ä¨ì²Ä¤@­Ó \0
        mov edi, esi
find_first_null:
        mov al, [edi]
        inc edi
        cmp al, 0
        jne find_first_null
        
        ; ÀË¬d¤U¤@­Ó¦r¤¸
        mov al, [edi]
        .IF al == 0
            ; ³æÀÉ¼Ò¦¡¡GszBatchFiles ¥]§t§¹¾ã¸ô®|
            mov batchFileCount, 1
            
            ; ½Æ»s¨ì szInputFile
            INVOKE ClearBuffer, ADDR szInputFile, 260
            lea esi, szBatchFiles
            lea edi, szInputFile
            mov ecx, 260
single_file_copy:
            lodsb
            stosb
            cmp al, 0
            je single_file_done
            loop single_file_copy
single_file_done:
            ; ÅçÃÒÀÉ®×
            INVOKE ValidateInputFile, ADDR szInputFile
            .IF eax == 0
                ret
            .ENDIF
            mov inputFileSize, eax
            
            ; ³æÀÉ¼Ò¦¡¡G¨Ï¥Î­ì¦³¬yµ{
            INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szReadyWithFile, ADDR szInputFile, inputFileSize
            INVOKE UpdateStatus, ADDR szStatusBuffer
            
            call SelectSaveFile
            .IF eax == 0
                ret
            .ENDIF
            
            INVOKE UpdateStatus, ADDR szCompressing
            call ResetProgress
            
            INVOKE Pro2_CompressFile, ADDR szInputFile, ADDR szOutputFile
            
            INVOKE UpdateProgress, 100, 100
            
            INVOKE GetCompressedFileSize, ADDR szOutputFile
            mov outputFileSize, eax
            
            .IF outputFileSize > 0
                call DisplayCompressionStats
            .ENDIF
            
            INVOKE MessageBoxA, hMainDialog, ADDR szSuccess, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
            INVOKE UpdateStatus, ADDR szStatus
            call ResetProgress
            INVOKE ClearBuffer, ADDR szInputFile, 260
            ret
        .ELSE
            ; ¦hÀÉ¼Ò¦¡¡G¨Ï¥Î»²§U¨ç¼Æ­«²Õ¸ô®|
            call RebuildFullPathsFromDialog
            mov batchFileCount, eax
            
            ; ÀË¬d¬O§_¦³ÀÉ®×
            .IF eax == 0
                INVOKE UpdateStatus, ADDR szNoFileSelected
                ret
            .ENDIF
            
            ; ©I¥s§å¦¸³B²z
            call ProcessBatchCompress
            
            ; ²MªÅ½w½Ä°Ï·Ç³Æ¤U¦¸¨Ï¥Î
            INVOKE ClearBuffer, ADDR szInputFile, 260
            INVOKE ClearBuffer, ADDR szBatchFiles, 65536
            ret
        .ENDIF
    .ENDIF  ; <-- µ²§ô skipDialog == 0 ªº±ø¥ó

    ; ³æÀÉ¼Ò¦¡¡]±q©ì©ñ¶i¤J¡^
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szReadyWithFile, ADDR szInputFile, inputFileSize
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    call SelectSaveFile
    .IF eax == 0
        ret
    .ENDIF
    
    INVOKE UpdateStatus, ADDR szCompressing
    call ResetProgress
    
    INVOKE Pro2_CompressFile, ADDR szInputFile, ADDR szOutputFile
    
    INVOKE UpdateProgress, 100, 100
    
    INVOKE GetCompressedFileSize, ADDR szOutputFile
    mov outputFileSize, eax
    
    .IF outputFileSize > 0
        call DisplayCompressionStats
    .ENDIF
        
    INVOKE MessageBoxA, hMainDialog, ADDR szSuccess, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    
    INVOKE UpdateStatus, ADDR szStatus
    call ResetProgress
    
    INVOKE ClearBuffer, ADDR szInputFile, 260
    
    ret
CompressFile ENDP

;-----------------------------------------------
; è§??ç¸®æ?æ¡ˆä¸»ç¨?
;-----------------------------------------------
DecompressFile PROC
    LOCAL ofn:OPENFILENAME
    LOCAL hFile:DWORD
    LOCAL decompressResult:DWORD
    LOCAL skipDialog:DWORD
    
    ; Check if szInputFile is already set (from drag & drop)
    mov skipDialog, 0
    mov al, szInputFile[0]
    .IF al != 0
        ; File already selected via drag & drop
        mov skipDialog, 1
    .ELSE
        ; Clear file path buffers
        INVOKE ClearBuffer, ADDR szInputFile, 260
        INVOKE ClearBuffer, ADDR szBatchFiles, 65536
    .ENDIF
    
    INVOKE ClearBuffer, ADDR szOutputFile, 260
    
    .IF skipDialog == 0
        ; ¥ý²MªÅ szBatchFiles ½w½Ä°Ï¡]½T«O¦h¿ï¥¿±`¹B§@¡^
        INVOKE ClearBuffer, ADDR szBatchFiles, 65536
        
        ; ³]©w OPENFILENAME µ²ºc
        INVOKE SetupOpenFileStruct, ADDR ofn, ADDR szBatchFiles, ADDR szFilterDecompress, ADDR szDecompressTitle
     
        ; Åã¥Ü¿ï¾ÜÀÉ®×¹ï¸Ü®Ø
        INVOKE GetOpenFileNameA, ADDR ofn
        .IF eax == 0
            ret
        .ENDIF
        
        ; ¸ÑªR¦hÀÉ®×¿ï¾Üµ²ªG
        ; ®æ¦¡¡Gdirectory\0file1\0file2\0\0
        lea esi, szBatchFiles
        
        ; ÀË¬d¬O³æÀÉÁÙ¬O¦hÀÉ
        ; §ä¨ì²Ä¤@­Ó \0
        mov edi, esi
find_first_null_decomp:
        mov al, [edi]
        inc edi
        cmp al, 0
        jne find_first_null_decomp
        
        ; ÀË¬d¤U¤@­Ó¦r¤¸
        mov al, [edi]
        .IF al == 0
            ; ³æÀÉ¼Ò¦¡¡GszBatchFiles ¥]§t§¹¾ã¸ô®|
            mov batchFileCount, 1
            
            ; ½Æ»s¨ì szInputFile
            INVOKE ClearBuffer, ADDR szInputFile, 260
            lea esi, szBatchFiles
            lea edi, szInputFile
            mov ecx, 260
single_file_copy_decomp:
            lodsb
            stosb
            cmp al, 0
            je single_file_done_decomp
            loop single_file_copy_decomp
single_file_done_decomp:
            ; ÅçÃÒÀÉ®×
            INVOKE ValidateInputFile, ADDR szInputFile
            .IF eax == 0
                ret
            .ENDIF
            mov inputFileSize, eax
            
            ; ³æÀÉ¼Ò¦¡¡G¨Ï¥Î­ì¦³¬yµ{
            INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szReadyWithFile, ADDR szInputFile, inputFileSize
            INVOKE UpdateStatus, ADDR szStatusBuffer
            
            call SelectSaveFileDecompress
            .IF eax == 0
                ret
            .ENDIF
            
            INVOKE UpdateStatus, ADDR szDecompressing
            call ResetProgress
            
            INVOKE DecompressHuffmanFile, ADDR szInputFile, ADDR szOutputFile
            
            INVOKE UpdateProgress, 100, 100
            
            INVOKE GetCompressedFileSize, ADDR szOutputFile
            mov outputFileSize, eax
            
            .IF outputFileSize > 0
                call DisplayDecompressionStats
            .ENDIF
            
            INVOKE MessageBoxA, hMainDialog, ADDR szSuccess, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
            INVOKE UpdateStatus, ADDR szStatus
            call ResetProgress
            INVOKE ClearBuffer, ADDR szInputFile, 260
            ret
        .ELSE
            ; ¦hÀÉ¼Ò¦¡¡G¨Ï¥Î»²§U¨ç¼Æ­«²Õ¸ô®|
            call RebuildFullPathsFromDialog
            mov batchFileCount, eax
            
            ; ÀË¬d¬O§_¦³ÀÉ®×
            .IF eax == 0
                INVOKE UpdateStatus, ADDR szNoFileSelected
                ret
            .ENDIF
            
            ; ©I¥s§å¦¸³B²z
            call ProcessBatchDecompress
            
            ; ²MªÅ½w½Ä°Ï·Ç³Æ¤U¦¸¨Ï¥Î
            INVOKE ClearBuffer, ADDR szInputFile, 260
            INVOKE ClearBuffer, ADDR szBatchFiles, 65536
            ret
        .ENDIF
    .ENDIF

    ; ³æÀÉ¼Ò¦¡¡]±q©ì©ñ¶i¤J¡^
    INVOKE ValidateInputFile, ADDR szInputFile
    .IF eax == 0
        ret
    .ENDIF
    mov inputFileSize, eax
    
    ; Åã¥ÜÀÉ®×¸ê°T
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szReadyWithFile, ADDR szInputFile, inputFileSize
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; ¿ï¾Ü¿é¥XÀÉ®×
    call SelectSaveFileDecompress
    .IF eax == 0
        ret
    .ENDIF

    ; §ó·sª¬ºA
    INVOKE UpdateStatus, ADDR szDecompressing
    
    ; ©I¥s¸ÑÀ£ÁY¨ç¼Æ
    INVOKE DecompressHuffmanFile, ADDR szInputFile, ADDR szOutputFile
    .IF eax != 0
        ; ¸ÑÀ£ÁY¦¨¥\¡AÅã¥Ü²Î­p
        INVOKE GetCompressedFileSize, ADDR szOutputFile
        mov outputFileSize, eax
        INVOKE DisplayDecompressionStats
    .ENDIF

    ; Åã¥Ü§¹¦¨°T®§
    INVOKE MessageBoxA, hMainDialog, ADDR szSuccess, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    
    INVOKE UpdateStatus, ADDR szStatus
    
    ; Clear input file for next operation
    INVOKE ClearBuffer, ADDR szInputFile, 260
    
    ret
DecompressFile ENDP

;-----------------------------------------------
; è¨­å? OPENFILENAME çµ??§å®¹
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
    mov (OPENFILENAME PTR [ebx]).nMaxFile, 65536
    mov (OPENFILENAME PTR [ebx]).lpstrFileTitle, NULL
    mov (OPENFILENAME PTR [ebx]).nMaxFileTitle, 0
    mov (OPENFILENAME PTR [ebx]).lpstrInitialDir, NULL
    mov eax, pTitle
    mov (OPENFILENAME PTR [ebx]).lpstrTitle, eax
    ; Use modern Explorer-style dialog with multi-select support
    mov (OPENFILENAME PTR [ebx]).Flags, OFN_FILEMUSTEXIST OR OFN_PATHMUSTEXIST OR OFN_EXPLORER OR OFN_ALLOWMULTISELECT
    mov (OPENFILENAME PTR [ebx]).nFileOffset, 0
    mov (OPENFILENAME PTR [ebx]).nFileExtension, 0
    mov (OPENFILENAME PTR [ebx]).lpstrDefExt, NULL
    mov (OPENFILENAME PTR [ebx]).lCustData, 0
    mov (OPENFILENAME PTR [ebx]).lpfnHook, NULL
    mov (OPENFILENAME PTR [ebx]).lpTemplateName, NULL
    
    ret
SetupOpenFileStruct ENDP

;-----------------------------------------------
; é©—è?è¼¸å…¥æª”æ?
; ?žå‚³ï¼šEAX = æª”æ?å¤§å?ï¼ˆå¤±?—å???0ï¼?
;-----------------------------------------------
ValidateInputFile PROC USES ebx, pszFilePath:PTR BYTE
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    
    ; ï¿½}ï¿½ï¿½ï¿½É®ï¿½
    INVOKE OpenFileForRead, pszFilePath
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE MessageBoxA, hMainDialog, ADDR szFileError, ADDR szError, MB_OK OR MB_ICONERROR
        xor eax, eax
    ret
    .ENDIF
    mov hFile, eax
    
    ; ï¿½ï¿½ï¿½oï¿½É®×¤jï¿½p
    INVOKE GetFileSize, hFile, NULL
    .IF eax == -1
        INVOKE CloseHandle, hFile
        INVOKE MessageBoxA, hMainDialog, ADDR szFileError, ADDR szError, MB_OK OR MB_ICONERROR
        xor eax, eax
        ret
    .ENDIF
    mov fileSize, eax
    
    ; ï¿½Ë¬dï¿½Oï¿½_ï¿½ï¿½ï¿½ï¿½ï¿½É®ï¿½
    .IF fileSize == 0
        INVOKE CloseHandle, hFile
        INVOKE MessageBoxA, hMainDialog, ADDR szEmptyFile, ADDR szError, MB_OK OR MB_ICONWARNING
    xor eax, eax
        ret
    .ENDIF
    
    ; ï¿½Ë¬dï¿½É®×¤jï¿½pï¿½]ï¿½ï¿½ï¿½ï¿½ 10MBï¿½^
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
; é¡¯ç¤ºå£“ç¸®?‡è???
;-----------------------------------------------
DisplayCompressionStats PROC USES eax ebx ecx edx
    LOCAL compressionRatio:DWORD
    
    ; ï¿½pï¿½ï¿½ï¿½ï¿½ï¿½Yï¿½v = (1 - compressed/original) * 100
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
    
    ; ï¿½æ¦¡ï¿½Æ°Tï¿½ï¿½
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szStatsFormat, 
       inputFileSize, outputFileSize, compressionRatio
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; ï¿½]ï¿½ï¿½Ü¦bï¿½Tï¿½ï¿½ï¿½Ø¤ï¿½
    INVOKE wsprintfA, ADDR szMessageBuffer, ADDR szStatsFormat, 
           inputFileSize, outputFileSize, compressionRatio
    INVOKE MessageBoxA, hMainDialog, ADDR szMessageBuffer, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    
    ret
DisplayCompressionStats ENDP

;-----------------------------------------------
; é¡¯ç¤ºè§??ç¸®è???
;-----------------------------------------------
DisplayDecompressionStats PROC
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szDecompStatsFormat, 
         outputFileSize, inputFileSize
    INVOKE UpdateStatus, ADDR szStatusBuffer
    ret
DisplayDecompressionStats ENDP

;-----------------------------------------------
; ?¸æ?å£“ç¸®æª”æ??²å?ä½ç½®
;-----------------------------------------------
SelectSaveFile PROC
    LOCAL ofn:OPENFILENAME
    
    ; ï¿½ï?Ê²ï¿½ï¿½Í¿ï¿½Xï¿½É¦W
    INVOKE GenerateOutputFilename, ADDR szInputFile, ADDR szOutputFile, ADDR hufExt
    
    ; ï¿½]ï¿½w OPENFILENAME ï¿½ï¿½ï¿½c
    INVOKE SetupSaveFileStruct, ADDR ofn, ADDR szOutputFile, ADDR szFilterSave
    
    ; ï¿½ï¿½ï¿½ï¿½xï¿½sï¿½É®×¹ï¿½Ü®ï¿?
    INVOKE GetSaveFileNameA, ADDR ofn
    ret
SelectSaveFile ENDP

;-----------------------------------------------
; ?¸æ?è§??ç¸®æ?æ¡ˆå„²å­˜ä?ç½?
;-----------------------------------------------
SelectSaveFileDecompress PROC
    LOCAL ofn:OPENFILENAME
    
    ; ï¿½ï?Ê²ï¿½ï¿½Í¿ï¿½Xï¿½É¦W
    INVOKE GenerateOutputFilename, ADDR szInputFile, ADDR szOutputFile, ADDR txtExt

    ; ï¿½]ï¿½w OPENFILENAME ï¿½ï¿½ï¿½c
    INVOKE SetupSaveFileStruct, ADDR ofn, ADDR szOutputFile, ADDR szFilterSave
    
    ; ï¿½ï¿½ï¿½ï¿½xï¿½sï¿½É®×¹ï¿½Ü®ï¿?
    INVOKE GetSaveFileNameA, ADDR ofn
    ret
SelectSaveFileDecompress ENDP

;-----------------------------------------------
; ?¢ç?è¼¸å‡ºæª”å?
;-----------------------------------------------
GenerateOutputFilename PROC USES esi edi, pszInput:PTR BYTE, pszOutput:PTR BYTE, pszExtension:PTR BYTE
    LOCAL lastDotPos:DWORD
    
    mov esi, pszInput
    mov edi, pszOutput
    mov lastDotPos, 0
    
    ; ï¿½Æ»sï¿½É¦Wï¿½Ã§ï¿½ï¿½Ì«ï¿½@ï¿½ï¿½ï¿½Iï¿½ï¿½ï¿½ï¿½m
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
    ; ï¿½pï¿½Gï¿½ï¿½ï¿½ï¿½Iï¿½Aï¿½^ï¿½ì¨ºï¿½Ó¦ï¿½m
    .IF lastDotPos != 0
        mov edi, pszOutput
        add edi, lastDotPos
    .ENDIF
 
    ; ï¿½ï¿½ï¿½[ï¿½sï¿½ï¿½ï¿½É¦W
    mov esi, pszExtension
append_ext:
    lodsb
    stosb
    cmp al, 0
    jne append_ext
    
    ret
GenerateOutputFilename ENDP

;-----------------------------------------------
; è¨­å??²å?æª”æ?å°è©±æ¡†ç?æ§?
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
    ; Use modern Explorer-style dialog for save
    mov (OPENFILENAME PTR [ebx]).Flags, OFN_OVERWRITEPROMPT OR OFN_PATHMUSTEXIST OR OFN_EXPLORER
    mov (OPENFILENAME PTR [ebx]).nFileOffset, 0
    mov (OPENFILENAME PTR [ebx]).nFileExtension, 0
    mov (OPENFILENAME PTR [ebx]).lpstrDefExt, NULL
    mov (OPENFILENAME PTR [ebx]).lCustData, 0
    mov (OPENFILENAME PTR [ebx]).lpfnHook, NULL
    mov (OPENFILENAME PTR [ebx]).lpTemplateName, NULL
    
    ret
SetupSaveFileStruct ENDP

;-----------------------------------------------
; æ¸…ç©ºç·©è??€
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
; ?´æ–°?€?‹è???
;-----------------------------------------------
UpdateStatus PROC USES eax, pszMessage:PTR BYTE
    INVOKE GetDlgItem, hMainDialog, IDC_EDIT_STATUS
    INVOKE SetWindowTextA, eax, pszMessage
    ret
UpdateStatus ENDP

;-----------------------------------------------
; ?–å?å£“ç¸®æª”æ?å¤§å?ï¼ˆè‹¥å¤±æ??žå‚³ 0ï¼?
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
; ä»¥ä??ºé€šç”¨ I/O ?½å?ï¼Œä??¶ä?æ¨¡ç??¼å«
;===============================================

;-----------------------------------------------
; ?‹å?æª”æ?ï¼ˆè??–ï?
;-----------------------------------------------
OpenFileForRead PROC, pszFilePath:PTR BYTE
    INVOKE CreateFileA, pszFilePath, GENERIC_READ, 0, NULL, 
   OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    ret
OpenFileForRead ENDP

;-----------------------------------------------
; ?‹å?æª”æ?ï¼ˆå¯«?¥ï?
;-----------------------------------------------
OpenFileForWrite PROC, pszFilePath:PTR BYTE
    INVOKE CreateFileA, pszFilePath, GENERIC_WRITE, 0, NULL,
           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    ret
OpenFileForWrite ENDP

;-----------------------------------------------
; è®€?–å–®ä¸€ä½å?çµ?
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
; å¯«å…¥?®ä?ä½å?çµ?
;-----------------------------------------------
WriteFileByte PROC USES ebx ecx edx, hFile:DWORD, byteVal:BYTE
    LOCAL bytesWritten:DWORD
    
    INVOKE WriteFile, hFile, ADDR byteVal, 1, ADDR bytesWritten, NULL
 ret
WriteFileByte ENDP

;-----------------------------------------------
; è®€?–ç·©è¡å?
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
; å¯«å…¥ç·©è??€
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
; ?œé?æª”æ?
;-----------------------------------------------
CloseFileHandle PROC, hFile:DWORD
    INVOKE CloseHandle, hFile
    ret
CloseFileHandle ENDP

;-----------------------------------------------
; ?–å?æª”æ?å¤§å?
;-----------------------------------------------
GetFileSizeEx PROC, hFile:DWORD
    INVOKE GetFileSize, hFile, NULL
    ret
GetFileSizeEx ENDP

;-----------------------------------------------
; ç§»å?æª”æ??‡æ?
;-----------------------------------------------
SeekFile PROC, hFile:DWORD, distanceToMove:SDWORD, moveMethod:DWORD
    INVOKE SetFilePointer, hFile, distanceToMove, NULL, moveMethod
    ret
SeekFile ENDP

;===============================================
; ?¶ä?å·¥å…·?½å?
;===============================================

;-----------------------------------------------
; CopyFile - è¤‡è£½æª”æ?ï¼ˆä?æ¸¬è©¦?¨ï?
; ?ƒæ•¸ï¼špszSource, pszDest
; ?žå‚³ï¼šEAX = 1 (?å?) ??0 (å¤±æ?)
;-----------------------------------------------
CopyFileData PROC USES ebx esi edi, pszSource:PTR BYTE, pszDest:PTR BYTE
    LOCAL hFileIn:DWORD
    LOCAL hFileOut:DWORD
    LOCAL buffer1[4096]:BYTE
    LOCAL bytesRead:DWORD
    
    ; ï¿½}ï¿½Ò¨Ó·ï¿½ï¿½É®ï¿½
    INVOKE OpenFileForRead, pszSource
    .IF eax == INVALID_HANDLE_VALUE
        xor eax, eax
        ret
    .ENDIF
    mov hFileIn, eax

    ; ï¿½}ï¿½Ò¥Øªï¿½ï¿½É®ï¿½
INVOKE OpenFileForWrite, pszDest
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE CloseFileHandle, hFileIn
        xor eax, eax
        ret
    .ENDIF
    mov hFileOut, eax
    
    ; ï¿½Æ»sï¿½ï¿½ï¿?
copy_loop:
    INVOKE ReadFileBuffer, hFileIn, ADDR buffer1, 4096
    mov bytesRead, eax
    .IF eax == 0
        jmp copy_done
    .ENDIF
    
    INVOKE WriteFileBuffer, hFileOut, ADDR buffer1, bytesRead
    .IF eax != bytesRead
        ; ï¿½gï¿½Jï¿½ï¿½ï¿½~
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
; CompareFiles - ês????©æ?æ¡ˆæ˜¯?¦ç›¸??
; ?ƒæ•¸ï¼špszFile1, pszFile2
; ?žå‚³ï¼šEAX = 1 (?¸å?) ??0 (ä¸å?/å¤±æ?)
;-----------------------------------------------
CompareFiles PROC USES ebx esi edi, pszFile1:PTR BYTE, pszFile2:PTR BYTE
    LOCAL hFile1:DWORD
    LOCAL hFile2:DWORD
    LOCAL buffer1[1024]:BYTE
    LOCAL buffer2[1024]:BYTE
    LOCAL bytesRead1:DWORD
    LOCAL bytesRead2:DWORD
    
    ; ï¿½}ï¿½ï¿½ï¿½É®ï¿½ 1
    INVOKE OpenFileForRead, pszFile1
    .IF eax == INVALID_HANDLE_VALUE
        xor eax, eax
        ret
    .ENDIF
    mov hFile1, eax
    
    ; ï¿½}ï¿½ï¿½ï¿½É±þ¿½ 2
    INVOKE OpenFileForRead, pszFile2
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE CloseFileHandle, hFile1
  xor eax, eax
        ret
    .ENDIF
    mov hFile2, eax
    
    ; ï¿½ï¿½ï¿½ï¿½É®×¤jï¿½p
    INVOKE GetFileSizeEx, hFile1
    mov ebx, eax
    INVOKE GetFileSizeEx, hFile2
    .IF eax != ebx
        ; ï¿½jï¿½pï¿½ï¿½ï¿½P
        INVOKE CloseFileHandle, hFile1
        INVOKE CloseFileHandle, hFile2
        xor eax, eax
        ret
    .ENDIF
    
    ; ï¿½vï¿½ï¿½ï¿½ï¿½ï¿?
compare_loop:
    INVOKE ReadFileBuffer, hFile1, ADDR buffer1, 1024
    mov bytesRead1, eax
    INVOKE ReadFileBuffer, hFile2, ADDR buffer2, 1024
    mov bytesRead2, eax
    ; ï¿½Ë¬dÅªï¿½ï¿½ï¿½Æ¶q
    mov eax, bytesRead1
    mov ebx, bytesRead2
    .IF eax != ebx
        INVOKE CloseFileHandle, hFile1
        INVOKE CloseFileHandle, hFile2
        xor eax, eax
      ret
    .ENDIF
    
 ; ï¿½pï¿½Gï¿½ï¿½Åªï¿½ï¿½ï¿½C
    .IF bytesRead1 == 0
     jmp compare_success
    .ENDIF
    
    ; ï¿½ï¿½ï¿½ï¿½wï¿½Ä°ï¿½
    lea esi, buffer1
    lea edi, buffer2
    mov ecx, bytesRead1
    repe cmpsb
    .IF !ZERO?
        ; ï¿½ï¿½ï¿½Û¦P
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

;-----------------------------------------------
; §ó·s¶i«×±ø
; position: ·í«e¶i«× (0-100)
; maxValue: ³Ì¤j­È (³q±`¬O 100)
;-----------------------------------------------
UpdateProgress PROC, position:DWORD, maxValue:DWORD
    push eax
    push ebx
    
    ; ­pºâ¦Ê¤À¤ñ
    mov eax, position
    mov ebx, 100
    mul ebx
    mov ebx, maxValue
    .IF ebx != 0
        div ebx
    .ELSE
        xor eax, eax
    .ENDIF
    
    ; §ó·s¶i«×±ø
    INVOKE SendMessageA, hProgressBar, PBM_SETPOS, eax, 0
    
    pop ebx
    pop eax
    ret
UpdateProgress ENDP

;-----------------------------------------------
; ­«¸m¶i«×±ø
;-----------------------------------------------
ResetProgress PROC
    INVOKE SendMessageA, hProgressBar, PBM_SETPOS, 0, 0
    ret
ResetProgress ENDP
;-----------------------------------------------
; ­«²Õ¹ï¸Ü®Ø¦hÀÉ®×®æ¦¡¬°§¹¾ã¸ô®|¼Æ²Õ
; ¿é¤J: szBatchFiles ¥]§t "dir\0file1\0file2\0\0"
; ¿é¥X: szBatchFiles ¥]§t§¹¾ã¸ô®|¡]¨C­Ó260¦r¸`¡^
; ªð¦^: EAX = ÀÉ®×¼Æ¶q
;-----------------------------------------------
RebuildFullPathsFromDialog PROC USES ebx esi edi
    ; ¨Ï¥Î .data ¬qªºÀRºA½w½Ä°Ï¡AÁ×§K°ïÅ|°ÝÃD
    
    ; Step 1: ²MªÅ¤u§@½w½Ä°Ï
    INVOKE ClearBuffer, ADDR tempDirPath, 260
    INVOKE ClearBuffer, ADDR tempFilePath, 260
    INVOKE ClearBuffer, ADDR tempFileList, 2600
    
    ; Step 2: ´£¨ú¥Ø¿ý¸ô®|
    lea esi, szBatchFiles
    lea edi, tempDirPath
extract_dir:
    lodsb
    stosb
    cmp al, 0
    jne extract_dir
    
    ; esi ²{¦b«ü¦V²Ä¤@­ÓÀÉ¦Wªº¶}©l¦ì¸m
    ; edi «ü¦V tempDirPath ¤¤ null «á­±ªº¦ì¸m
    
    ; ½T«O¥Ø¿ý¥H¤Ï±×½uµ²§À
    ; ­º¥ý¦^¨ì null ªº¦ì¸m
    dec edi
    ; ¦A¦^¨ì³Ì«á¤@­Ó¹ê»Ú¦r¤¸
    dec edi
    cmp byte ptr [edi], '\'
    je dir_already_has_slash
    ; ¨S¦³¤Ï±×½u¡A¥[¤W¤Ï±×½u
    inc edi
    mov byte ptr [edi], '\'
dir_already_has_slash:
    ; ²¾¨ì¤Ï±×½u«á­±¡A¥[¤W null
    inc edi
    mov byte ptr [edi], 0
    
    ; Step 3: ¦¬¶°©Ò¦³ÀÉ¦W¨ì tempFileList
    xor ebx, ebx  ; fileCount = 0
    
collect_files:
    mov al, [esi]
    cmp al, 0
    je collect_done
    
    ; ÀË¬d¬O§_¶W¹L10­ÓÀÉ®×
    cmp ebx, 10
    jge collect_done
    
    ; ²MªÅ tempFilePath
    push esi
    push ebx
    INVOKE ClearBuffer, ADDR tempFilePath, 260
    pop ebx
    pop esi
    
    ; «Øºc§¹¾ã¸ô®|¨ì tempFilePath
    push esi
    push ebx
    
    ; ½Æ»s¥Ø¿ý
    lea esi, tempDirPath
    lea edi, tempFilePath
copy_dir_temp:
    lodsb
    cmp al, 0
    je copy_dir_temp_done
    stosb
    jmp copy_dir_temp
copy_dir_temp_done:
    ; edi ²{¦b«ü¦V tempFilePath ¤¤¥Ø¿ýµ²§ô«áªº¦ì¸m¡]·Ç³Æ±µÀÉ¦W¡^
    
    pop ebx
    pop esi
    
    ; ½Æ»sÀÉ¦W
copy_filename_temp:
    lodsb
    stosb
    cmp al, 0
    jne copy_filename_temp
    
    ; ½Æ»s tempFilePath ¨ìtempFileList[fileCount * 260]
    push esi
    lea esi, tempFilePath
    
    ; ­pºâ tempFileList[fileCount * 260] ªº¦a§}
    mov eax, ebx
    mov edx, 260
    imul eax, edx
    lea edi, tempFileList
    add edi, eax
    
    mov ecx, 260
copy_to_list:
    lodsb
    stosb
    loop copy_to_list
    
    pop esi
    inc ebx
    jmp collect_files
    
collect_done:
    ; Step 4: ²MªÅ szBatchFiles ¨Ã½Æ»s¦^¥h
    INVOKE ClearBuffer, ADDR szBatchFiles, 65536
    
    lea esi, tempFileList
    lea edi, szBatchFiles
    mov ecx, ebx  ; fileCount
    
    .IF ecx > 0
        mov edx, 260
        imul ecx, edx
        rep movsb
    .ENDIF
    
    mov eax, ebx  ; ªð¦^ÀÉ®×¼Æ¶q
    ret
RebuildFullPathsFromDialog ENDP

;-----------------------------------------------
; §å¦¸À£ÁY³B²z
;-----------------------------------------------
ProcessBatchCompress PROC
    LOCAL fileIndex:DWORD
    LOCAL pCurrentFile:DWORD
    
    mov fileIndex, 0
    lea eax, szBatchFiles
    mov pCurrentFile, eax
    
    call ResetProgress
    
batch_compress_loop:
    mov eax, fileIndex
    cmp eax, batchFileCount
    jge batch_compress_done
    
    ; §ó·sª¬ºA°T®§
    inc eax
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szBatchProcessing, 
           eax, batchFileCount
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; §ó·s¶i«×±ø
    mov eax, fileIndex
    inc eax
    INVOKE UpdateProgress, eax, batchFileCount
    
    ; ½Æ»s·í«eÀÉ®×¸ô®|¨ì szInputFile
    INVOKE ClearBuffer, ADDR szInputFile, 260
    mov esi, pCurrentFile
    lea edi, szInputFile
    mov ecx, 260
copy_path_loop:
    lodsb
    stosb
    cmp al, 0
    je copy_path_done
    loop copy_path_loop
copy_path_done:
    
    ; ÅçÃÒÀÉ®×
    INVOKE ValidateInputFile, ADDR szInputFile
    .IF eax != 0
        mov inputFileSize, eax
        
        ; ¦Û°Ê²£¥Í¿é¥XÀÉ¦W
        INVOKE GenerateOutputFilename, ADDR szInputFile, ADDR szOutputFile, ADDR hufExt
        
        ; À£ÁYÀÉ®×
        INVOKE Pro2_CompressFile, ADDR szInputFile, ADDR szOutputFile
    .ENDIF
    
    ; ²¾¨ì¤U¤@­ÓÀÉ®×
    inc fileIndex
    add pCurrentFile, 260
    jmp batch_compress_loop
    
batch_compress_done:
    ; Åã¥Ü§¹¦¨°T®§
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szBatchComplete, batchFileCount
    INVOKE UpdateStatus, ADDR szStatusBuffer
    INVOKE MessageBoxA, hMainDialog, ADDR szStatusBuffer, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    
    call ResetProgress
    INVOKE UpdateStatus, ADDR szStatus
    ret
ProcessBatchCompress ENDP

;-----------------------------------------------
; §å¦¸¸ÑÀ£ÁY³B²z
;-----------------------------------------------
ProcessBatchDecompress PROC
    LOCAL fileIndex:DWORD
    LOCAL pCurrentFile:DWORD
    
    mov fileIndex, 0
    lea eax, szBatchFiles
    mov pCurrentFile, eax
    
    call ResetProgress
    
batch_decompress_loop:
    mov eax, fileIndex
    cmp eax, batchFileCount
    jge batch_decompress_done
    
    ; §ó·sª¬ºA°T®§
    inc eax
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szBatchProcessing, 
           eax, batchFileCount
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; §ó·s¶i«×±ø
    mov eax, fileIndex
    inc eax
    INVOKE UpdateProgress, eax, batchFileCount
    
    ; ½Æ»s·í«eÀÉ®×¸ô®|¨ì szInputFile
    INVOKE ClearBuffer, ADDR szInputFile, 260
    mov esi, pCurrentFile
    lea edi, szInputFile
    mov ecx, 260
copy_path_loop2:
    lodsb
    stosb
    cmp al, 0
    je copy_path_done2
    loop copy_path_loop2
copy_path_done2:
    
    ; ÅçÃÒÀÉ®×
    INVOKE ValidateInputFile, ADDR szInputFile
    .IF eax != 0
        mov inputFileSize, eax
        
        ; ¦Û°Ê²£¥Í¿é¥XÀÉ¦W¡]²¾°£ .huff¡A¥[¤W .txt¡^
        INVOKE GenerateOutputFilename, ADDR szInputFile, ADDR szOutputFile, ADDR txtExt
        
        ; ¸ÑÀ£ÁYÀÉ®×
        INVOKE DecompressHuffmanFile, ADDR szInputFile, ADDR szOutputFile
    .ENDIF
    
    ; ²¾¨ì¤U¤@­ÓÀÉ®×
    inc fileIndex
    add pCurrentFile, 260
    jmp batch_decompress_loop
    
batch_decompress_done:
    ; Åã¥Ü§¹¦¨°T®§
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szBatchComplete, batchFileCount
    INVOKE UpdateStatus, ADDR szStatusBuffer
    INVOKE MessageBoxA, hMainDialog, ADDR szStatusBuffer, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    
    call ResetProgress
    INVOKE UpdateStatus, ADDR szStatus
    ret
ProcessBatchDecompress ENDP

END main














