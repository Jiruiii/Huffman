
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
    LOCAL rootNode:DWORD
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
    ; Header / serialization format (proposal - must be agreed with encoder):
    ; - DWORD (4 bytes, little-endian): treeBytes  (number of bytes in the serialized tree)
    ; - treeBytes bytes: pre-order serialization of the tree:
    ;     For each node in pre-order:
    ;       0x00 -> internal node
    ;       0x01 <char> -> leaf node followed by the byte value
    ; - DWORD (4 bytes): originalFileSize (number of output bytes after decompression)
    ; After the header follows the compressed bitstream.
    ;
    ; TODO: Read the DWORD treeBytes, read the treeBytes into a buffer,
    ;       reconstruct nodes into a dynamically allocated array and set
    ;       rootNode = pointer to the root HuffNode.
    ;       (Implementation left as next step; below code assumes `rootNode` will
    ;       be set before entering the decode loop.)

    ; 3. Bit-level decoding main loop
    mov bitCount, 0
    ; Initialize root pointer (must be set after header parsing)
    mov rootNode, 0
    mov esi, rootNode ; current node pointer (will be reset after tree built)
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
    ; Extract MSB from bitBuffer.
    ; Strategy: examine bit 7, produce 0/1 in BL, then shift buffer left.
    mov al, bitBuffer
    mov bl, al
    and bl, 80h       ; isolate MSB
    shr bl, 7         ; bl = 0 or 1
    shl al, 1         ; consume MSB by shifting left
    mov bitBuffer, al
    dec bitCount

    ; Traverse Huffman tree according to bit (bl)
    ; esi = current node pointer, rootNode must be set earlier
    cmp esi, 0
    jne .has_node
    ; If esi is not initialized, try using rootNode
    mov esi, rootNode
.has_node:
    cmp bl, 0
    je .go_left
    ; go right
    mov esi, DWORD PTR [esi + HuffNode.right]
    jmp .after_move
.go_left:
    mov esi, DWORD PTR [esi + HuffNode.left]
.after_move:

    ; Check if current node is a leaf: left==0 and right==0
    mov eax, DWORD PTR [esi + HuffNode.left]
    or eax, DWORD PTR [esi + HuffNode.right]
    jz .is_leaf

    jmp decode_loop

.is_leaf:
    mov al, BYTE PTR [esi + HuffNode.char]
    INVOKE WriteFileByte, hOut, al
    ; After writing a leaf, return to root
    mov esi, rootNode
    jmp decode_loop
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
