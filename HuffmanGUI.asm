.386
.model flat, stdcall
option casemap :none

INCLUDE Irvine32.inc
INCLUDE macros.inc

; Windows API ÂÆ??
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

; Ê™îÊ? I/O API
CreateFileA PROTO, lpFileName:PTR BYTE, dwDesiredAccess:DWORD, dwShareMode:DWORD,
    lpSecurityAttributes:DWORD, dwCreationDisposition:DWORD, dwFlagsAndAttributes:DWORD, hTemplateFile:DWORD
; ReadFile and WriteFile are already defined in Windows libraries
CloseHandle PROTO, hObject:DWORD
GetFileSize PROTO, hFile:DWORD, lpFileSizeHigh:DWORD
; SetFilePointer is already defined in Windows libraries
MessageBoxA PROTO, hWnd:DWORD, lpText:PTR BYTE, lpCaption:PTR BYTE, uType:DWORD

; String ®Á¶°
wsprintfA PROTO C, lpOut:PTR BYTE, lpFmt:PTR BYTE, args:VARARG

; •~≥°®Áº∆≠Ï´¨°]®”¶€§H≠˚§G°B§T°B•|™∫º“≤’°^
Pro2_CompressFile PROTO, pszInputFile:PTR BYTE, pszOutputFile:PTR BYTE
DecompressHuffmanFile PROTO, pszInputFile:PTR BYTE, pszOutputFile:PTR BYTE

; æ…•X§Ω•Œ®Áº∆®—®‰•Lº“≤’®œ•Œ

; Â∞éÂá∫?¨Áî®?ΩÊï∏‰æõÂÖ∂‰ªñÊ®°ÁµÑ‰Ωø??
PUBLIC OpenFileForRead
PUBLIC OpenFileForWrite
PUBLIC ReadFileByte
PUBLIC WriteFileByte
PUBLIC ReadFileBuffer
PUBLIC WriteFileBuffer
PUBLIC CloseFileHandle
PUBLIC GetFileSizeEx
PUBLIC SeekFile

; Â∏∏Êï∏ÂÆöÁæ©?Ä
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

; OPENFILENAME ÁµêÊ?
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
; ?®Â?ËÆäÊï∏?Ä
hInstance  DWORD ?
hMainDialog     DWORD ?
hProgressBar    DWORD ?
szInputFile     BYTE 260 DUP(0)
szOutputFile    BYTE 260 DUP(0)
inputFileSize   DWORD ?
outputFileSize  DWORD ?

; ßÂ¶∏≥B≤z≈‹º∆
szBatchFiles    BYTE 65536 DUP(0)  ; ¿x¶s¶h≠”¿…Æ◊∏ÙÆ|°]®C≠”≥Ã¶h 260 bytes°^
batchFileCount  DWORD 0
currentFileIndex DWORD 0

; Ê™îÊ??éÊøæ??
szFilterCompress    BYTE "Text Files (*.txt)",0,"*.txt",0
      BYTE "All Files (*.*)",0,"*.*",0,0
huffFilterStr       BYTE "Huffman Files (*.huff)",0,"*.huff",0
         BYTE "All Files (*.*)",0,"*.*",0,0
szFilterDecompress  BYTE "Huffman Files (*.huff)",0,"*.huff",0
         BYTE "All Files (*.*)",0,"*.*",0,0
szFilterSave        BYTE "Huffman Files (*.huff)",0,"*.huff",0
            BYTE "Text Files (*.txt)",0,"*.txt",0,0

; ?áÂ?Ë®äÊÅØ
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

; Â£ìÁ∏Æ?áË??ØÊ†ºÂºèÂ?‰∏?
szStatsFormat       BYTE "Input: %d bytes | Output: %d bytes | Compression: %d%%",0
szDecompStatsFormat BYTE "Decompressed: %d bytes from %d bytes compressed file",0
szReadyWithFile     BYTE "Selected: %s (%d bytes)",0

; ?Ä?ãÊö´Â≠òÂ?
szStatusBuffer      BYTE 512 DUP(0)
szMessageBuffer  BYTE 512 DUP(0)

; ?ØÊ??çÂ?‰∏?
hufExt BYTE ".huff",0
txtExt BYTE ".txt",0

; ?§ÈåØË®äÊÅØ
szDebugMsg BYTE "Building Huffman Tree...",0

; ?çÁΩÆÂÆ?? (Forward Declarations)
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

.code

; ================================================
; Á®ãÂ??≤ÂÖ•Èª?
;-----------------------------------------------
main PROC
    INVOKE GetModuleHandleA, NULL
    mov hInstance, eax
    
    ; DialogBoxParam with numeric resource ID
    INVOKE DialogBoxParamA, hInstance, 101, NULL, ADDR DlgProc, 0
    
    INVOKE ExitProcess, 0
main ENDP

;-----------------------------------------------
; ‰∏ªË?Á™óË??ØË??ÜÁ?Â∫?
;-----------------------------------------------
DlgProc PROC, hDlg:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    .IF uMsg == WM_INITDIALOG
        mov eax, hDlg
        mov hMainDialog, eax
        
        ; Enable drag & drop
        INVOKE DragAcceptFiles, hDlg, TRUE
        
        ; ™Ï©l§∆™¨∫A¶C
        INVOKE GetDlgItem, hDlg, IDC_EDIT_STATUS
        INVOKE SetWindowTextA, eax, ADDR szStatus
        
        ; ™Ï©l§∆∂i´◊±¯
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
        ; Handle drag & drop - §‰¥©¶h¿…Æ◊
        push ebx
        push esi
        push edi
        mov ebx, wParam  ; hDrop handle
        
        ; ®˙±o©Ï©Ò¿…Æ◊º∆∂q
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
        
        ; ≤M™≈ßÂ¶∏¿…Æ◊ΩwΩƒ∞œ
        INVOKE ClearBuffer, ADDR szBatchFiles, 65536
        
        ; ≈™®˙©“¶≥©Ï©Ò™∫¿…Æ◊∏ÙÆ|
        xor esi, esi  ; ¿…Æ◊Ø¡§ﬁ
        lea edi, szBatchFiles
        
read_dropped_files:
        cmp esi, batchFileCount
        jge dropped_files_done
        
        ; ≈™®˙≤ƒ i ≠”¿…Æ◊∏ÙÆ|
        INVOKE DragQueryFileA, ebx, esi, edi, 260
        .IF eax != 0
            ; ≤æ∞ ®Ï§U§@≠”¿…Æ◊∏ÙÆ|¶Ï∏m°]®C≠”∏ÙÆ|¶˚ 260 bytes°^
            add edi, 260
            inc esi
            jmp read_dropped_files
        .ENDIF
        
dropped_files_done:
        INVOKE DragFinish, ebx
        
        ; ßP¬_¨O¿£¡Y¡Ÿ¨O∏—¿£¡Y°]Æ⁄æ⁄≤ƒ§@≠”¿…Æ◊™∫∞∆¿…¶W°^
        lea esi, szBatchFiles
        
        ; ¿À¨d∞∆¿…¶W
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
                    ; .huff ¿…Æ◊ -> ßÂ¶∏∏—¿£¡Y
                    call ProcessBatchDecompress
                    pop edi
                    pop esi
                    pop ebx
                    mov eax, TRUE
                    ret
                .ENDIF
            .ENDIF
        .ENDIF
        
        ; πw≥]°GßÂ¶∏¿£¡Y
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
; Â£ìÁ∏ÆÊ™îÊ?ÊµÅÁ?ÔºàÂ?Âº∑Á?Ôº?
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
        ; ≥]©w OPENFILENAME µ≤∫c°]§‰¥©¶h¿…Æ◊øÔæ‹°^
        INVOKE SetupOpenFileStruct, ADDR ofn, ADDR szBatchFiles, ADDR szFilterCompress, ADDR szCompressTitle
     
        ; ≈„•‹øÔæ‹¿…Æ◊πÔ∏‹Æÿ
        INVOKE GetOpenFileNameA, ADDR ofn
      .IF eax == 0
            ret
        .ENDIF

        ; ∏—™R¶h¿…Æ◊øÔæ‹µ≤™G
        ; ÆÊ¶°°Gdirectory\0file1\0file2\0\0
        lea esi, szBatchFiles
        
        ; ¿À¨d¨O≥Ê¿…¡Ÿ¨O¶h¿…
        ; ß‰®Ï≤ƒ§@≠” \0
        mov edi, esi
find_first_null:
        mov al, [edi]
        inc edi
        cmp al, 0
        jne find_first_null
        
        ; ¿À¨d§U§@≠”¶r§∏
        mov al, [edi]
        .IF al == 0
            ; ≥Ê¿…º“¶°°GszBatchFiles •]ßtßπæ„∏ÙÆ|
            mov batchFileCount, 1
            
            ; Ω∆ªs®Ï szInputFile
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
            ; ≈Á√“¿…Æ◊
            INVOKE ValidateInputFile, ADDR szInputFile
            .IF eax == 0
                ret
            .ENDIF
            mov inputFileSize, eax
            
            ; ≥Ê¿…º“¶°°G®œ•Œ≠Ï¶≥¨yµ{
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
            ; ¶h¿…º“¶°°Gª›≠n≠´≤’ßπæ„∏ÙÆ|
            ; TODO: πÍß@¶h¿…∏ÙÆ|≠´≤’°]∏˚Ω∆¬¯°Aº»Æ…®œ•ŒßÂ¶∏≥B≤z°^
            ; ≥o∏Ã¬≤§∆≥B≤z°G≠p∫‚¿…Æ◊º∆∂q
            mov batchFileCount, 0
            lea esi, szBatchFiles
            
            ; ∏ıπL•ÿø˝∏ÙÆ|
skip_dir:
            lodsb
            cmp al, 0
            jne skip_dir
            
            ; ≠p∫‚¿…Æ◊º∆∂q
count_files:
            mov al, [esi]
            cmp al, 0
            je count_done
            
            inc batchFileCount
            
            ; ∏ı®Ï§U§@≠”¿…¶W
skip_filename:
            lodsb
            cmp al, 0
            jne skip_filename
            jmp count_files
            
count_done:
            ; ©I•sßÂ¶∏≥B≤z
            call ProcessBatchCompress
            ret
        .ENDIF
    .ENDIF

    ; ≥Ê¿…º“¶°°]±q©Ï©Ò∂i§J°^
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
; Ëß??Á∏ÆÊ?Ê°à‰∏ªÁ®ãÂ?
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
        ; ≤M∞£¿…??∏Ù??Ωw????
        INVOKE ClearBuffer, ADDR szInputFile, 260
    .ENDIF
    
    INVOKE ClearBuffer, ADDR szOutputFile, 260
    
    .IF skipDialog == 0
        ; ≥]?? OPENFILENAME µ≤??
      INVOKE SetupOpenFileStruct, ADDR ofn, ADDR szInputFile, ADDR szFilterDecompress, ADDR szDecompressTitle
     
        ; ≈„•‹????¿…??πÔ∏‹??
        INVOKE GetOpenFileNameA, ADDR ofn
        .IF eax == 0
      ret
        .ENDIF
        
        ; ≈Á??¿…??
        INVOKE ValidateInputFile, ADDR szInputFile
        .IF eax == 0
          ret
    .ENDIF
      mov inputFileSize, eax
    .ENDIF

    ; È°ØÁ§∫Ê™îÊ?Ë≥áË?
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szReadyWithFile, ADDR szInputFile, inputFileSize
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; È°ØÁ§∫Ëº∏Âá∫Ê™îÊ?
    call SelectSaveFileDecompress
    .IF eax == 0
        ret
    .ENDIF

    ; ?¥Êñ∞?Ä??    
    INVOKE UpdateStatus, ADDR szDecompressing
    
    ; ?ºÂè´‰∫„Wì°?õÁ?Ëß??Á∏ÆÂáΩÂº?
    INVOKE DecompressHuffmanFile, ADDR szInputFile, ADDR szOutputFile
    .IF eax != 0
 ; Ëß??Á∏ÆÊ??üÔ?È°ØÁ§∫Áµ±Ë?
     INVOKE GetCompressedFileSize, ADDR szOutputFile
        mov outputFileSize, eax
      INVOKE DisplayDecompressionStats
    .ENDIF

    ; ≈„•‹ßπ??∞TÆß??
    INVOKE MessageBoxA, hMainDialog, ADDR szSuccess, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    
    INVOKE UpdateStatus, ADDR szStatus
    
    ; Clear input file for next operation
    INVOKE ClearBuffer, ADDR szInputFile, 260
    
    ret
DecompressFile ENDP

;-----------------------------------------------
; Ë®≠Â? OPENFILENAME ÁµêÊ??ßÂÆπ
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
; È©óË?Ëº∏ÂÖ•Ê™îÊ?
; ?ûÂÇ≥ÔºöEAX = Ê™îÊ?Â§ßÂ?ÔºàÂ§±?óÂ???0Ôº?
;-----------------------------------------------
ValidateInputFile PROC USES ebx, pszFilePath:PTR BYTE
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    
    ; ÔøΩ}ÔøΩÔøΩÔøΩ…ÆÔøΩ
    INVOKE OpenFileForRead, pszFilePath
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE MessageBoxA, hMainDialog, ADDR szFileError, ADDR szError, MB_OK OR MB_ICONERROR
        xor eax, eax
    ret
    .ENDIF
    mov hFile, eax
    
    ; ÔøΩÔøΩÔøΩoÔøΩ…Æ◊§jÔøΩp
    INVOKE GetFileSize, hFile, NULL
    .IF eax == -1
        INVOKE CloseHandle, hFile
        INVOKE MessageBoxA, hMainDialog, ADDR szFileError, ADDR szError, MB_OK OR MB_ICONERROR
        xor eax, eax
        ret
    .ENDIF
    mov fileSize, eax
    
    ; ÔøΩÀ¨dÔøΩOÔøΩ_ÔøΩÔøΩÔøΩÔøΩÔøΩ…ÆÔøΩ
    .IF fileSize == 0
        INVOKE CloseHandle, hFile
        INVOKE MessageBoxA, hMainDialog, ADDR szEmptyFile, ADDR szError, MB_OK OR MB_ICONWARNING
    xor eax, eax
        ret
    .ENDIF
    
    ; ÔøΩÀ¨dÔøΩ…Æ◊§jÔøΩpÔøΩ]ÔøΩÔøΩÔøΩÔøΩ 10MBÔøΩ^
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
; È°ØÁ§∫Â£ìÁ∏Æ?áË???
;-----------------------------------------------
DisplayCompressionStats PROC USES eax ebx ecx edx
    LOCAL compressionRatio:DWORD
    
    ; ÔøΩpÔøΩÔøΩÔøΩÔøΩÔøΩYÔøΩv = (1 - compressed/original) * 100
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
    
    ; ÔøΩÊ¶°ÔøΩ∆∞TÔøΩÔøΩ
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szStatsFormat, 
       inputFileSize, outputFileSize, compressionRatio
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; ÔøΩ]ÔøΩÔøΩ‹¶bÔøΩTÔøΩÔøΩÔøΩÿ§ÔøΩ
    INVOKE wsprintfA, ADDR szMessageBuffer, ADDR szStatsFormat, 
           inputFileSize, outputFileSize, compressionRatio
    INVOKE MessageBoxA, hMainDialog, ADDR szMessageBuffer, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    
    ret
DisplayCompressionStats ENDP

;-----------------------------------------------
; È°ØÁ§∫Ëß??Á∏ÆË???
;-----------------------------------------------
DisplayDecompressionStats PROC
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szDecompStatsFormat, 
         outputFileSize, inputFileSize
    INVOKE UpdateStatus, ADDR szStatusBuffer
    ret
DisplayDecompressionStats ENDP

;-----------------------------------------------
; ?∏Ê?Â£ìÁ∏ÆÊ™îÊ??≤Â?‰ΩçÁΩÆ
;-----------------------------------------------
SelectSaveFile PROC
    LOCAL ofn:OPENFILENAME
    
    ; ÔøΩÔ? ≤ÔøΩÔøΩÕøÔøΩXÔøΩ…¶W
    INVOKE GenerateOutputFilename, ADDR szInputFile, ADDR szOutputFile, ADDR hufExt
    
    ; ÔøΩ]ÔøΩw OPENFILENAME ÔøΩÔøΩÔøΩc
    INVOKE SetupSaveFileStruct, ADDR ofn, ADDR szOutputFile, ADDR szFilterSave
    
    ; ÔøΩÔøΩÔøΩÔøΩxÔøΩsÔøΩ…Æ◊πÔøΩ‹ÆÔø?
    INVOKE GetSaveFileNameA, ADDR ofn
    ret
SelectSaveFile ENDP

;-----------------------------------------------
; ?∏Ê?Ëß??Á∏ÆÊ?Ê°àÂÑ≤Â≠ò‰?ÁΩ?
;-----------------------------------------------
SelectSaveFileDecompress PROC
    LOCAL ofn:OPENFILENAME
    
    ; ÔøΩÔ? ≤ÔøΩÔøΩÕøÔøΩXÔøΩ…¶W
    INVOKE GenerateOutputFilename, ADDR szInputFile, ADDR szOutputFile, ADDR txtExt

    ; ÔøΩ]ÔøΩw OPENFILENAME ÔøΩÔøΩÔøΩc
    INVOKE SetupSaveFileStruct, ADDR ofn, ADDR szOutputFile, ADDR szFilterSave
    
    ; ÔøΩÔøΩÔøΩÔøΩxÔøΩsÔøΩ…Æ◊πÔøΩ‹ÆÔø?
    INVOKE GetSaveFileNameA, ADDR ofn
    ret
SelectSaveFileDecompress ENDP

;-----------------------------------------------
; ?¢Á?Ëº∏Âá∫Ê™îÂ?
;-----------------------------------------------
GenerateOutputFilename PROC USES esi edi, pszInput:PTR BYTE, pszOutput:PTR BYTE, pszExtension:PTR BYTE
    LOCAL lastDotPos:DWORD
    
    mov esi, pszInput
    mov edi, pszOutput
    mov lastDotPos, 0
    
    ; ÔøΩ∆ªsÔøΩ…¶WÔøΩ√ßÔøΩÔøΩÃ´ÔøΩ@ÔøΩÔøΩÔøΩIÔøΩÔøΩÔøΩÔøΩm
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
    ; ÔøΩpÔøΩGÔøΩÔøΩÔøΩÔøΩIÔøΩAÔøΩ^ÔøΩÏ®∫ÔøΩ”¶ÔøΩm
    .IF lastDotPos != 0
        mov edi, pszOutput
        add edi, lastDotPos
    .ENDIF
 
    ; ÔøΩÔøΩÔøΩ[ÔøΩsÔøΩÔøΩÔøΩ…¶W
    mov esi, pszExtension
append_ext:
    lodsb
    stosb
    cmp al, 0
    jne append_ext
    
    ret
GenerateOutputFilename ENDP

;-----------------------------------------------
; Ë®≠Â??≤Â?Ê™îÊ?Â∞çË©±Ê°ÜÁ?Êß?
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
; Ê∏ÖÁ©∫Á∑©Ë??Ä
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
; ?¥Êñ∞?Ä?ãË???
;-----------------------------------------------
UpdateStatus PROC USES eax, pszMessage:PTR BYTE
    INVOKE GetDlgItem, hMainDialog, IDC_EDIT_STATUS
    INVOKE SetWindowTextA, eax, pszMessage
    ret
UpdateStatus ENDP

;-----------------------------------------------
; ?ñÂ?Â£ìÁ∏ÆÊ™îÊ?Â§ßÂ?ÔºàËã•Â§±Ê??ûÂÇ≥ 0Ôº?
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
; ‰ª•‰??∫ÈÄöÁî® I/O ?ΩÂ?Ôºå‰??∂‰?Ê®°Á??ºÂè´
;===============================================

;-----------------------------------------------
; ?ãÂ?Ê™îÊ?ÔºàË??ñÔ?
;-----------------------------------------------
OpenFileForRead PROC, pszFilePath:PTR BYTE
    INVOKE CreateFileA, pszFilePath, GENERIC_READ, 0, NULL, 
   OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    ret
OpenFileForRead ENDP

;-----------------------------------------------
; ?ãÂ?Ê™îÊ?ÔºàÂØ´?•Ô?
;-----------------------------------------------
OpenFileForWrite PROC, pszFilePath:PTR BYTE
    INVOKE CreateFileA, pszFilePath, GENERIC_WRITE, 0, NULL,
           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    ret
OpenFileForWrite ENDP

;-----------------------------------------------
; ËÆÄ?ñÂñÆ‰∏Ä‰ΩçÂ?Áµ?
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
; ÂØ´ÂÖ•?Æ‰?‰ΩçÂ?Áµ?
;-----------------------------------------------
WriteFileByte PROC USES ebx ecx edx, hFile:DWORD, byteVal:BYTE
    LOCAL bytesWritten:DWORD
    
    INVOKE WriteFile, hFile, ADDR byteVal, 1, ADDR bytesWritten, NULL
 ret
WriteFileByte ENDP

;-----------------------------------------------
; ËÆÄ?ñÁ∑©Ë°ùÂ?
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
; ÂØ´ÂÖ•Á∑©Ë??Ä
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
; ?úÈ?Ê™îÊ?
;-----------------------------------------------
CloseFileHandle PROC, hFile:DWORD
    INVOKE CloseHandle, hFile
    ret
CloseFileHandle ENDP

;-----------------------------------------------
; ?ñÂ?Ê™îÊ?Â§ßÂ?
;-----------------------------------------------
GetFileSizeEx PROC, hFile:DWORD
    INVOKE GetFileSize, hFile, NULL
    ret
GetFileSizeEx ENDP

;-----------------------------------------------
; ÁßªÂ?Ê™îÊ??áÊ?
;-----------------------------------------------
SeekFile PROC, hFile:DWORD, distanceToMove:SDWORD, moveMethod:DWORD
    INVOKE SetFilePointer, hFile, distanceToMove, NULL, moveMethod
    ret
SeekFile ENDP

;===============================================
; ?∂‰?Â∑•ÂÖ∑?ΩÂ?
;===============================================

;-----------------------------------------------
; CopyFile - Ë§áË£ΩÊ™îÊ?Ôºà‰?Ê∏¨Ë©¶?®Ô?
; ?ÉÊï∏ÔºöpszSource, pszDest
; ?ûÂÇ≥ÔºöEAX = 1 (?êÂ?) ??0 (Â§±Ê?)
;-----------------------------------------------
CopyFileData PROC USES ebx esi edi, pszSource:PTR BYTE, pszDest:PTR BYTE
    LOCAL hFileIn:DWORD
    LOCAL hFileOut:DWORD
    LOCAL buffer[4096]:BYTE
    LOCAL bytesRead:DWORD
    
    ; ÔøΩ}ÔøΩ“®”∑ÔøΩÔøΩ…ÆÔøΩ
    INVOKE OpenFileForRead, pszSource
    .IF eax == INVALID_HANDLE_VALUE
        xor eax, eax
        ret
    .ENDIF
    mov hFileIn, eax

    ; ÔøΩ}ÔøΩ“•ÿ™ÔøΩÔøΩ…ÆÔøΩ
INVOKE OpenFileForWrite, pszDest
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE CloseFileHandle, hFileIn
        xor eax, eax
        ret
    .ENDIF
    mov hFileOut, eax
    
    ; ÔøΩ∆ªsÔøΩÔøΩÔø?
copy_loop:
    INVOKE ReadFileBuffer, hFileIn, ADDR buffer, 4096
    mov bytesRead, eax
    .IF eax == 0
        jmp copy_done
    .ENDIF
    
    INVOKE WriteFileBuffer, hFileOut, ADDR buffer, bytesRead
    .IF eax != bytesRead
        ; ÔøΩgÔøΩJÔøΩÔøΩÔøΩ~
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
; CompareFiles - Ís????©Ê?Ê°àÊòØ?¶Áõ∏??
; ?ÉÊï∏ÔºöpszFile1, pszFile2
; ?ûÂÇ≥ÔºöEAX = 1 (?∏Â?) ??0 (‰∏çÂ?/Â§±Ê?)
;-----------------------------------------------
CompareFiles PROC USES ebx esi edi, pszFile1:PTR BYTE, pszFile2:PTR BYTE
    LOCAL hFile1:DWORD
    LOCAL hFile2:DWORD
    LOCAL buffer1[1024]:BYTE
    LOCAL buffer2[1024]:BYTE
    LOCAL bytesRead1:DWORD
    LOCAL bytesRead2:DWORD
    
    ; ÔøΩ}ÔøΩÔøΩÔøΩ…ÆÔøΩ 1
    INVOKE OpenFileForRead, pszFile1
    .IF eax == INVALID_HANDLE_VALUE
        xor eax, eax
        ret
    .ENDIF
    mov hFile1, eax
    
    ; ÔøΩ}ÔøΩÔøΩÔøΩ…±˛øΩ 2
    INVOKE OpenFileForRead, pszFile2
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE CloseFileHandle, hFile1
  xor eax, eax
        ret
    .ENDIF
    mov hFile2, eax
    
    ; ÔøΩÔøΩÔøΩÔøΩ…Æ◊§jÔøΩp
    INVOKE GetFileSizeEx, hFile1
    mov ebx, eax
    INVOKE GetFileSizeEx, hFile2
    .IF eax != ebx
        ; ÔøΩjÔøΩpÔøΩÔøΩÔøΩP
        INVOKE CloseFileHandle, hFile1
        INVOKE CloseFileHandle, hFile2
        xor eax, eax
        ret
    .ENDIF
    
    ; ÔøΩvÔøΩÔøΩÔøΩÔøΩÔø?
compare_loop:
    INVOKE ReadFileBuffer, hFile1, ADDR buffer1, 1024
    mov bytesRead1, eax
    INVOKE ReadFileBuffer, hFile2, ADDR buffer2, 1024
    mov bytesRead2, eax
    ; ÔøΩÀ¨d≈™ÔøΩÔøΩÔøΩ∆∂q
    mov eax, bytesRead1
    mov ebx, bytesRead2
    .IF eax != ebx
        INVOKE CloseFileHandle, hFile1
        INVOKE CloseFileHandle, hFile2
        xor eax, eax
      ret
    .ENDIF
    
 ; ÔøΩpÔøΩGÔøΩÔøΩ≈™ÔøΩÔøΩÔøΩC
    .IF bytesRead1 == 0
     jmp compare_success
    .ENDIF
    
    ; ÔøΩÔøΩÔøΩÔøΩwÔøΩƒ∞ÔøΩ
    lea esi, buffer1
    lea edi, buffer2
    mov ecx, bytesRead1
    repe cmpsb
    .IF !ZERO?
        ; ÔøΩÔøΩÔøΩ€¶P
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
; ßÛ∑s∂i´◊±¯
; position: ∑Ì´e∂i´◊ (0-100)
; maxValue: ≥Ã§j≠» (≥q±`¨O 100)
;-----------------------------------------------
UpdateProgress PROC, position:DWORD, maxValue:DWORD
    push eax
    push ebx
    
    ; ≠p∫‚¶ §¿§Ò
    mov eax, position
    mov ebx, 100
    mul ebx
    mov ebx, maxValue
    .IF ebx != 0
        div ebx
    .ELSE
        xor eax, eax
    .ENDIF
    
    ; ßÛ∑s∂i´◊±¯
    INVOKE SendMessageA, hProgressBar, PBM_SETPOS, eax, 0
    
    pop ebx
    pop eax
    ret
UpdateProgress ENDP

;-----------------------------------------------
; ≠´∏m∂i´◊±¯
;-----------------------------------------------
ResetProgress PROC
    INVOKE SendMessageA, hProgressBar, PBM_SETPOS, 0, 0
    ret
ResetProgress ENDP

;-----------------------------------------------
; ßÂ¶∏¿£¡Y≥B≤z
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
    
    ; ßÛ∑s™¨∫A∞TÆß
    inc eax
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szBatchProcessing, 
           eax, batchFileCount
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; ßÛ∑s∂i´◊±¯
    mov eax, fileIndex
    inc eax
    INVOKE UpdateProgress, eax, batchFileCount
    
    ; Ω∆ªs∑Ì´e¿…Æ◊∏ÙÆ|®Ï szInputFile
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
    
    ; ≈Á√“¿…Æ◊
    INVOKE ValidateInputFile, ADDR szInputFile
    .IF eax != 0
        mov inputFileSize, eax
        
        ; ¶€∞ ≤£•ÕøÈ•X¿…¶W
        INVOKE GenerateOutputFilename, ADDR szInputFile, ADDR szOutputFile, ADDR hufExt
        
        ; ¿£¡Y¿…Æ◊
        INVOKE Pro2_CompressFile, ADDR szInputFile, ADDR szOutputFile
    .ENDIF
    
    ; ≤æ®Ï§U§@≠”¿…Æ◊
    inc fileIndex
    add pCurrentFile, 260
    jmp batch_compress_loop
    
batch_compress_done:
    ; ≈„•‹ßπ¶®∞TÆß
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szBatchComplete, batchFileCount
    INVOKE UpdateStatus, ADDR szStatusBuffer
    INVOKE MessageBoxA, hMainDialog, ADDR szStatusBuffer, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    
    call ResetProgress
    INVOKE UpdateStatus, ADDR szStatus
    ret
ProcessBatchCompress ENDP

;-----------------------------------------------
; ßÂ¶∏∏—¿£¡Y≥B≤z
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
    
    ; ßÛ∑s™¨∫A∞TÆß
    inc eax
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szBatchProcessing, 
           eax, batchFileCount
    INVOKE UpdateStatus, ADDR szStatusBuffer
    
    ; ßÛ∑s∂i´◊±¯
    mov eax, fileIndex
    inc eax
    INVOKE UpdateProgress, eax, batchFileCount
    
    ; Ω∆ªs∑Ì´e¿…Æ◊∏ÙÆ|®Ï szInputFile
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
    
    ; ≈Á√“¿…Æ◊
    INVOKE ValidateInputFile, ADDR szInputFile
    .IF eax != 0
        mov inputFileSize, eax
        
        ; ¶€∞ ≤£•ÕøÈ•X¿…¶W°]≤æ∞£ .huff°A•[§W .txt°^
        INVOKE GenerateOutputFilename, ADDR szInputFile, ADDR szOutputFile, ADDR txtExt
        
        ; ∏—¿£¡Y¿…Æ◊
        INVOKE DecompressHuffmanFile, ADDR szInputFile, ADDR szOutputFile
    .ENDIF
    
    ; ≤æ®Ï§U§@≠”¿…Æ◊
    inc fileIndex
    add pCurrentFile, 260
    jmp batch_decompress_loop
    
batch_decompress_done:
    ; ≈„•‹ßπ¶®∞TÆß
    INVOKE wsprintfA, ADDR szStatusBuffer, ADDR szBatchComplete, batchFileCount
    INVOKE UpdateStatus, ADDR szStatusBuffer
    INVOKE MessageBoxA, hMainDialog, ADDR szStatusBuffer, ADDR szAppTitle, MB_OK OR MB_ICONINFORMATION
    
    call ResetProgress
    INVOKE UpdateStatus, ADDR szStatus
    ret
ProcessBatchDecompress ENDP

END main

