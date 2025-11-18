
; Huffman Decoder (Member 4)
; Main tasks: Read .huff file, reconstruct Huffman tree, and restore original data
; Interface: DecompressHuffmanFile PROTO, pszInputFile:PTR BYTE, pszOutputFile:PTR BYTE

INCLUDE Irvine32.inc

; Huffman tree node structure
HuffNode STRUCT
    freq  DWORD ?
    char  BYTE  ?
    left  DWORD ?
    right DWORD ?
HuffNode ENDS

; Main decompression procedure

DecompressHuffmanFile PROC USES esi edi ebx,
    pszInputFile:PTR BYTE,
    pszOutputFile:PTR BYTE
    LOCAL hIn:DWORD
    LOCAL hOut:DWORD
    LOCAL bitBuffer:BYTE
    LOCAL bitCount:DWORD
    ; 1. Open input and output files
    INVOKE OpenFileForRead, pszInputFile
    mov hIn, eax
    .IF eax == INVALID_HANDLE_VALUE
        ret
    .ENDIF
    INVOKE OpenFileForWrite, pszOutputFile
    mov hOut, eax
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE CloseFileHandle, hIn
        ret
    .ENDIF

    ; 2. Read header and reconstruct Huffman tree (must match encoder format)
    ; TODO: Read serialized tree data and rebuild tree structure

    ; 3. Bit-level decoding main loop
    mov bitCount, 0
decode_loop:
    ; If bitCount == 0, read a new byte
    mov eax, bitCount
    .IF eax == 0
        INVOKE ReadFileByte, hIn
        .IF eax == -1
            jmp decode_end
        .ENDIF
        mov bitBuffer, al
        mov bitCount, 8
    .ENDIF

    ; Extract highest bit (bit 7)
    mov al, bitBuffer
    shl al, 1

    rcl bl, 1   ; bl = current bit
    dec bitCount

    ; TODO: Traverse Huffman tree according to bit (bl)
    ; Assume esi = current node pointer, initially root
    ; bl = 0: go left, bl = 1: go right
    ; mov esi, [esi].left or mov esi, [esi].right

    ; TODO: If esi points to a leaf node (left/right == 0)
    ;   mov al, [esi].char
    ;   INVOKE WriteFileByte, hOut, al
    ;   mov esi, root node

    jmp decode_loop

decode_end:
    ; 4. Close files
    INVOKE CloseFileHandle, hIn
    INVOKE CloseFileHandle, hOut
    mov eax, 1 ; 成功
    ret
DecompressHuffmanFile ENDP

; Additional helper functions can be added here

END
