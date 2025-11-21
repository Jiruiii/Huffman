
; Huffman Decoder (Member 4)
; Main tasks: Read .huff file, reconstruct Huffman tree, and restore original data
; Interface: DecompressHuffmanFile PROTO, pszInputFile:PTR BYTE, pszOutputFile:PTR BYTE

INCLUDE Irvine32.inc

.data
; Buffer for serialized tree (max 16KB to be safe)
TreeBuf BYTE 16384 DUP(?)
TreeBufIndex DWORD 0
TreeBytes DWORD 0
OriginalSize DWORD 0

; Node allocation buffer for decoder
NODE_BUFFER_SIZE_DEC = 512 * 16
NodeBufferDec BYTE NODE_BUFFER_SIZE_DEC DUP(?)
NextNodePtrDec DWORD OFFSET NodeBufferDec
OutWrittenCount DWORD 0
.code

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
    ; Read treeBytes (DWORD, little-endian)
    mov eax, 0
    INVOKE ReadFileByte, hIn
    mov al, al
    mov bl, al
    mov eax, ebx
    INVOKE ReadFileByte, hIn
    mov al, al
    shl eax, 8
    or eax, eax
    INVOKE ReadFileByte, hIn
    mov al, al
    shl eax, 8
    or eax, eax
    INVOKE ReadFileByte, hIn
    mov al, al
    shl eax, 8
    or eax, eax
    mov TreeBytes, eax

    ; Read serialized tree bytes into TreeBuf
    mov ecx, TreeBytes
    mov edi, 0
read_tree_bytes_loop:
    cmp ecx, 0
    je tree_bytes_done
    INVOKE ReadFileByte, hIn
    mov TreeBuf[edi], al
    inc edi
    dec ecx
    jmp read_tree_bytes_loop
tree_bytes_done:

    ; Read originalFileSize (DWORD little-endian)
    mov eax, 0
    INVOKE ReadFileByte, hIn
    mov al, al
    mov ebx, eax
    INVOKE ReadFileByte, hIn
    mov al, al
    shl ebx, 8
    or ebx, eax
    INVOKE ReadFileByte, hIn
    mov al, al
    shl ebx, 8
    or ebx, eax
    INVOKE ReadFileByte, hIn
    mov al, al
    shl ebx, 8
    or ebx, eax
    mov OriginalSize, ebx

    ; Prepare to rebuild tree from TreeBuf
    mov TreeBufIndex, 0
    mov NextNodePtrDec, OFFSET NodeBufferDec
    ; call recursive builder
    call RebuildNodeFromBuffer
    mov rootNode, eax
    mov esi, rootNode
    mov OutWrittenCount, 0

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
    ; increment output count and stop if we've written originalSize bytes
    mov eax, OutWrittenCount
    inc eax
    mov OutWrittenCount, eax
    mov eax, OutWrittenCount
    cmp eax, OriginalSize
    jne decode_continue
    jmp decode_end
decode_continue:
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

; --------------------------------------------------------------------
; AllocNode - allocate space for a HuffNode from NodeBufferDec
; Returns: EAX = pointer to node
; --------------------------------------------------------------------
AllocNode PROC
    push ebp
    mov ebp, esp
    push ebx

    mov eax, NextNodePtrDec
    add NextNodePtrDec, SIZEOF HuffNode
    mov ebx, eax

    ; initialize
    mov DWORD PTR [ebx + HuffNode.freq], 0
    mov BYTE PTR [ebx + HuffNode.char], 0
    mov DWORD PTR [ebx + HuffNode.left], 0
    mov DWORD PTR [ebx + HuffNode.right], 0

    mov eax, ebx
    pop ebx
    mov esp, ebp
    pop ebp
    ret
AllocNode ENDP


; --------------------------------------------------------------------
; RebuildNodeFromBuffer - recursively rebuild Huffman tree from TreeBuf
; Returns: EAX = pointer to rebuilt node
; --------------------------------------------------------------------
RebuildNodeFromBuffer PROC
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ; load current marker
    mov ebx, TreeBufIndex
    mov al, TreeBuf[ebx]
    ; increment index
    add dword ptr TreeBufIndex, 1
    cmp al, 1
    je .leaf

    ; internal node
    call AllocNode
    mov edx, eax ; edx = this node
    ; build left
    call RebuildNodeFromBuffer
    mov DWORD PTR [edx + HuffNode.left], eax
    ; build right
    call RebuildNodeFromBuffer
    mov DWORD PTR [edx + HuffNode.right], eax
    mov eax, edx
    jmp .done

.leaf:
    ; read character byte
    mov ebx, TreeBufIndex
    mov al, TreeBuf[ebx]
    add dword ptr TreeBufIndex, 1
    call AllocNode
    mov BYTE PTR [eax + HuffNode.char], al
    mov DWORD PTR [eax + HuffNode.left], 0
    mov DWORD PTR [eax + HuffNode.right], 0

.done:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret
RebuildNodeFromBuffer ENDP

END
