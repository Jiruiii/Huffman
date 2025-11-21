INCLUDE Irvine32.inc

; 外部函式原型（與專案中實作名稱一致）
Pro2_CompressFile PROTO, pszSrc:PTR BYTE, pszDst:PTR BYTE
DecompressHuffmanFile PROTO, pszInputFile:PTR BYTE, pszOutputFile:PTR BYTE
CompareFiles PROTO, pszFile1:PTR BYTE, pszFile2:PTR BYTE
MessageBoxA PROTO, hWnd:DWORD, lpText:PTR BYTE, lpCaption:PTR BYTE, uType:DWORD
ExitProcess PROTO, uExitCode:DWORD

.data
srcFile      BYTE "test_input.txt",0
compressed   BYTE "test_out.huff",0
restored     BYTE "test_restored.txt",0
okMsg       BYTE "Huffman test passed: restored file matches original.",0
failMsg     BYTE "Huffman test failed.",0
titleStr    BYTE "Huffman Test Runner",0

.code
main PROC
    ; 1) Compress
    INVOKE Pro2_CompressFile, ADDR srcFile, ADDR compressed
    .IF eax == 0
        INVOKE MessageBoxA, NULL, ADDR failMsg, ADDR titleStr, MB_OK OR MB_ICONERROR
        INVOKE ExitProcess, 1
    .ENDIF

    ; 2) Decompress
    INVOKE DecompressHuffmanFile, ADDR compressed, ADDR restored
    .IF eax == 0
        INVOKE MessageBoxA, NULL, ADDR failMsg, ADDR titleStr, MB_OK OR MB_ICONERROR
        INVOKE ExitProcess, 2
    .ENDIF

    ; 3) Compare
    INVOKE CompareFiles, ADDR srcFile, ADDR restored
    .IF eax == 1
        INVOKE MessageBoxA, NULL, ADDR okMsg, ADDR titleStr, MB_OK OR MB_ICONINFORMATION
        INVOKE ExitProcess, 0
    .ELSE
        INVOKE MessageBoxA, NULL, ADDR failMsg, ADDR titleStr, MB_OK OR MB_ICONERROR
        INVOKE ExitProcess, 3
    .ENDIF

main ENDP
END