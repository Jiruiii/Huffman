.386
.model flat, stdcall
option casemap :none

; Include Irvine32 library
INCLUDE Irvine32.inc

PUBLIC BuildHuffmanTree
PUBLIC BuildHuffmanTree_File

includelib kernel32.lib

; File read buffer for CountFrequencyFromFile
ReadBuf2 BYTE 4096 DUP(?)
ReadCount2 DWORD 0
InFileHandle2 DWORD 0


main        EQU start@0

; Huffman Tree Node Structure Definition (Ch. 10 STRUCT Application)
HuffNode STRUCT
    freq  DWORD ?     ; Total occurrences (frequency) of the node/subtree
    char  BYTE  ?     ; Stored character (leaf nodes only, 0-255)
    _pad  BYTE  3 DUP(?) ; Alignment padding
    left  DWORD ?     ; Pointer to left child (Offset)
    right DWORD ?     ; Pointer to right child (Offset)
HuffNode ENDS

.data
; --------------------------------------------------------------------
; Data Segment Variables
; --------------------------------------------------------------------
; Frequency table for 256 bytes (each DWORD is 4 bytes)
FrequencyTable DWORD 256 DUP(0)

; Array to store all non-zero frequency node pointers (max 511 nodes)
NodePointers DWORD 512 DUP(0)
NodeCount    DWORD 0        ; Current number of nodes in the NodePointers array

; Test string for simulating file input (replace with file I/O in implementation)
TestString   BYTE "AAAAAABBBCCDDDEEFFFF", 0
TestStringLen DWORD SIZEOF TestString - 1

msg_freq_count BYTE "--- Step 1: Frequency count done ---", 0dh, 0ah, 0
msg_tree_done  BYTE "--- Step 2: Huffman tree build done ---", 0dh, 0ah, 0
msg_root       BYTE "Root node frequency: ", 0

; --------------------------------------------------------------------
; Node allocation buffer (must be in writable data segment)
; --------------------------------------------------------------------
NODE_BUFFER_SIZE = 512 * SIZEOF HuffNode ; Buffer for 512 nodes
NodeBuffer BYTE NODE_BUFFER_SIZE DUP(?)
NextNodePtr DWORD OFFSET NodeBuffer      ; Starting address of the next available node

.code
; ====================================================================
; Helper Function: Simulate Node Allocation
; ====================================================================
; (Node buffer moved to .data to ensure writable memory for NextNodePtr)

; --------------------------------------------------------------------
; PROC: AllocNode
; Purpose: Simulate dynamic allocation of a new HuffNode space
; Returns: EAX = Address (Offset) of the new node
; --------------------------------------------------------------------
AllocNode PROC
    PUSH EBX ; Only need to save EBX
    
    MOV EAX, NextNodePtr   ; Get the next available address
    ADD NextNodePtr, SIZEOF HuffNode ; Update the pointer to the next position
    MOV EBX, EAX ; Save the new node address
    
    ; Initialize new node contents (Important: Ensure pointers are NULL)
    MOV (HuffNode PTR [EBX]).freq, 0
    MOV (HuffNode PTR [EBX]).char, 0
    MOV (HuffNode PTR [EBX]).left, 0
    MOV (HuffNode PTR [EBX]).right, 0
    MOV EAX, EBX ; Return the new node address
    
    POP EBX
    RET
AllocNode ENDP

; --------------------------------------------------------------------
; PROC: CountFrequency
; Purpose: Count the occurrence frequency of each character.
; --------------------------------------------------------------------
CountFrequency PROC
    ; Deprecated: use CountFrequencyFromFile for real files
    RET
CountFrequency ENDP


; --------------------------------------------------------------------
; PROC: CountFrequencyFromFile (stdcall)
; Purpose: Read an input file and fill FrequencyTable
; Params: [esp+4] = pointer to NUL-terminated path (ANSI)
; Returns: EAX = 1 on success, 0 on failure
; --------------------------------------------------------------------
CountFrequencyFromFile PROC
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    push ecx

    mov esi, dword ptr [ebp+8] ; input path pointer
    ; Open file
    INVOKE CreateFileA, esi, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    mov InFileHandle2, eax
    cmp eax, INVALID_HANDLE_VALUE
    je cf_fail

    ; Read loop
    lea edi, FrequencyTable
  cf_read_loop:
    INVOKE ReadFile, dword ptr InFileHandle2, ADDR ReadBuf2, 4096, ADDR ReadCount2, 0
    mov ecx, ReadCount2
    cmp ecx, 0
    je cf_done
    mov ebx, 0 ; buffer index
  cf_bytes_loop:
    mov al, ReadBuf2[ebx]
    movzx edx, al
    ; index *4
    mov eax, edx
    shl eax, 2
    add eax, OFFSET FrequencyTable
    inc DWORD PTR [eax]
    inc ebx
    dec ecx
    jnz cf_bytes_loop
    jmp cf_read_loop

  cf_done:
    INVOKE CloseHandle, InFileHandle2
    mov eax, 1
    jmp cf_cleanup

  cf_fail:
    mov eax, 0

  cf_cleanup:
    pop ecx
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4
CountFrequencyFromFile ENDP


; New wrapper: BuildHuffmanTree_File(inputPathPtr)
; stdcall: caller pushes inputPathPtr; returns EAX = rootPtr or 0
BuildHuffmanTree_File PROC
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov esi, dword ptr [ebp+8] ; inputPathPtr
    ; clear FrequencyTable
    mov ecx, 256
    lea edi, FrequencyTable
    xor eax, eax
bf_clear_loop:
    mov [edi], eax
    add edi, 4
    loop bf_clear_loop

    ; count frequencies from file
    push esi
    call CountFrequencyFromFile
    ; ignore return for now

    ; call existing BuildHuffmanTree (no args)
    call BuildHuffmanTree
    ; EAX is rootPtr

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4
BuildHuffmanTree_File ENDP

; --------------------------------------------------------------------
; PROC: FindMin (V28: Replaces FindTwoMin, bypasses A2206 Bug)
; Purpose: Find the node with the minimum frequency in the NodePointers array.
; Input: EAX = Index to skip (SkipIdx), -1 means do not skip.
; Returns: EAX = Index of the minimum frequency node (idx)
; --------------------------------------------------------------------
FindMin PROC
    PUSH ESI
    PUSH ECX
    PUSH EDX
    PUSH EBX
    PUSH EDI
    PUSH EBP

    MOV ESI, 0FFFFFFFFh ; ESI = min_freq (最大無符號整數)
    MOV EBP, -1         ; EBP = min_idx
    MOV EDX, EAX        ; EDX = SkipIdx
    MOV ECX, NodeCount
    MOV EDI, 0          ; EDI = CurrentIdx

  FindMinLoop_V28:
    CMP ECX, 0
    JE FindMinDone_V28

    CMP EDI, EDX
    JE SkipNode_V28

    MOV EBX, EDI
    ADD EBX, EBX
    ADD EBX, EBX
    ADD EBX, OFFSET NodePointers
    MOV EBX, DWORD PTR [EBX]
    
    CMP EBX, 0
    JE SkipNode_V28

    MOV EBX, (HuffNode PTR [EBX]).freq

    CMP EBX, ESI
    JAE SkipNode_V28    ; ← 改這裡！使用無符號比較

    MOV ESI, EBX
    MOV EBP, EDI
    
  SkipNode_V28:
    INC EDI
    DEC ECX
    JMP FindMinLoop_V28

  FindMinDone_V28:
    MOV EAX, EBP

    POP EBP
    POP EDI
    POP EBX
    POP EDX
    POP ECX
    POP ESI
    RET
FindMin ENDP

; --------------------------------------------------------------------
; PROC: BuildHuffmanTree
; Purpose: Build Huffman tree based on frequency table and return root node pointer.
; --------------------------------------------------------------------
BuildHuffmanTree PROC
    PUSH ESI
    PUSH EDI
    PUSH ECX
    PUSH EDX
    PUSH EBX
    ; PUSH EAX  ; <-- V30 FIX: EAX is the return register, DO NOT PUSH/POP it.

    ; --- 1. Initialize Leaf Node Setup ---
    MOV NodeCount, 0
    MOV ECX, 256  ; 256 loops
    MOV ESI, OFFSET FrequencyTable ; frequency table start address
    MOV EDI, 0    ; character value (0-255)

  NodeInitLoop:
    CMP DWORD PTR [ESI], 0
    JE NextChar     ; frequency is 0, skip

    ; frequency > 0, create node
    INVOKE AllocNode ; EAX = new node address (leaf node)
    MOV EBX, EAX     ; EBX stores new node address

    ; Set node properties
    MOV EDX, [ESI]   ; EDX = Frequency
    MOV (HuffNode PTR [EBX]).freq, EDX ; Set frequency

    ; Safely transfer character value from EDI to AL
    MOV EAX, EDI  ; Transfer character value (0-255) to EAX 
    MOV (HuffNode PTR [EBX]).char, AL ; Set character (using AL)
    
    ; --- V29 FIX: Load NodeCount *before* address calculation ---
    PUSH EDX            ; 1. Save EDX (which holds Frequency)
    MOV EDX, NodeCount  ; 2. (!!! FIX !!!) Load EDX with the correct index (NodeCount)
    ADD EDX, EDX        ; 3. EDX = offset (NodeCount * 2)
    ADD EDX, EDX        ; 4. EDX = offset (NodeCount * 4)
    ADD EDX, OFFSET NodePointers ; 5. EDX = full address (NodePointers[NodeCount])
    MOV DWORD PTR [EDX], EBX ; 6. Write the node pointer (EBX) to the correct address
    POP EDX             ; 7. Restore EDX (Frequency)
    
    INC NodeCount

  NextChar:
    ADD ESI, 4       ; Move to the next frequency DWORD
    INC EDI          ; Next character value
    LOOP NodeInitLoop

    ; --- 2. Huffman Tree Merging ---
  MergeLoop:
    CMP NodeCount, 1
    JLE MergeDone    ; Node count <= 1, tree build complete

    ; --- V20 Fix: Call FindMin twice ---
    
    ; 1. Find the index of the first minimum node
    MOV EAX, -1         ; SkipIdx = -1 (do not skip)
    INVOKE FindMin      ; EAX = idx1
    PUSH EAX            ; Store idx1 on the stack

    ; 2. Find the index of the second minimum node (EAX is still idx1)
    INVOKE FindMin      ; EAX = idx2 (because EAX=idx1 was passed in)
    
    MOV EBX, EAX        ; EBX = idx2
    POP EAX             ; EAX = idx1

    ; Check if returned indices are valid (avoid -1)
    CMP EAX, -1
    JE MergeDone
    CMP EBX, -1
    JE MergeDone

    ; --- V23 Fix: Replace all SHL reg, 2 ---
    
    ; 3. Get the addresses of the two nodes (P1/P2)
    ; Read P1 (idx1 = EAX)
    PUSH EBX            ; Save EBX (idx2)
    MOV EBX, EAX        ; EBX = index (EAX)
    ADD EBX, EBX
    ADD EBX, EBX
    ADD EBX, OFFSET NodePointers
    MOV ESI, DWORD PTR [EBX] ; ESI = P1
    POP EBX             ; Restore EBX (idx2)

    ; Read P2 (idx2 = EBX)
    PUSH EAX            ; Save EAX (idx1)
    ; (!!! V32 FIX !!!) EBX (idx2) is the index, we must use a scratch register
    MOV EAX, EBX        ; 1. Copy idx2 (EBX) to EAX (scratch register)
    ADD EAX, EAX        ; 2. EAX = idx2 * 2
    ADD EAX, EAX        ; 3. EAX = idx2 * 4
    ADD EAX, OFFSET NodePointers ; 4. EAX = Addr(NodePointers[idx2])
    MOV EDI, DWORD PTR [EAX] ; 5. EDI = P2
    POP EAX             ; Restore EAX (idx1)
    ; (EBX was never modified, no PUSH/POP EBX needed)


    ; 4. Create new Internal Node
    ; Save idx1 (EAX) and idx2 (EBX) because AllocNode returns pointer in EAX
    PUSH EAX            ; Save idx1
    PUSH EBX            ; Save idx2
    INVOKE AllocNode    ; EAX = NewNodePtr (new node address)
    MOV EDX, EAX        ; EDX = NewNodePtr
    POP EBX             ; Restore idx2
    POP EAX             ; Restore idx1

    ; 5. Calculate new frequency = P1.freq + P2.freq
    MOV ECX, (HuffNode PTR [ESI]).freq
    ADD ECX, (HuffNode PTR [EDI]).freq

    ; 6. Set new node properties
    MOV (HuffNode PTR [EDX]).freq, ECX  ; Set new frequency
    MOV (HuffNode PTR [EDX]).left, ESI  ; Set left child to P1
    MOV (HuffNode PTR [EDX]).right, EDI ; Set right child to P2

    ; 7. Update NodePointers array
    ; Put the new node (P_New) in P1's position (EAX)
    PUSH EBX            ; Save EBX (idx2)
    MOV EBX, EAX        ; EBX = index (EAX)
    ADD EBX, EBX
    ADD EBX, EBX
    ADD EBX, OFFSET NodePointers
    MOV DWORD PTR [EBX], EDX ; Write P_New
    POP EBX             ; Restore EBX (idx2)

    ; Replace P2's position (EBX) with the last node in the array
    DEC NodeCount
    MOV ECX, NodeCount ; ECX = index of the last element
    
    ; Read the last node (ESI = LastNodePtr)
    PUSH EAX
    PUSH EBX
    MOV EBX, ECX
    ADD EBX, EBX
    ADD EBX, EBX
    ADD EBX, OFFSET NodePointers
    MOV ESI, DWORD PTR [EBX]
    POP EBX
    POP EAX

    ; Write LastNodePtr to P2's position (EBX)
    PUSH EAX
    ; (!!! V32 FIX !!!) EBX (idx2) is the index, we must use a scratch register
    MOV EAX, EBX        ; 1. Copy idx2 (EBX) to EAX (scratch register)
    ADD EAX, EAX        ; 2. EAX = idx2 * 2
    ADD EAX, EAX        ; 3. EAX = idx2 * 4
    ADD EAX, OFFSET NodePointers ; 4. EAX = Addr(NodePointers[idx2])
    MOV DWORD PTR [EAX], ESI ; 5. Write LastNodePtr
    POP EAX             ; Restore EAX (idx1)
    
    ; Clear the last position
    PUSH EAX
    PUSH EBX
    MOV EBX, ECX
    ADD EBX, EBX
    ADD EBX, EBX
    ADD EBX, OFFSET NodePointers
    MOV DWORD PTR [EBX], 0
    POP EBX
    POP EAX
    
    JMP MergeLoop

  MergeDone:
    ; Tree build complete, root node is in NodePointers[0]
    MOV EBX, OFFSET NodePointers
    MOV EAX, DWORD PTR [EBX] ; Return root node pointer

    ; POP EAX ; <-- V30 FIX: Removed corresponding POP
    POP EBX
    POP EDX
    POP ECX
    POP EDI
    POP ESI
    
    ; Output status message (V4 Fix: ADDR -> OFFSET)
    MOV EDX, OFFSET msg_tree_done
    INVOKE WriteString
    INVOKE Crlf

    RET
BuildHuffmanTree ENDP


; --------------------------------------------------------------------
; Main code (for testing Personnel 2's logic)
; --------------------------------------------------------------------
main PROC
    ; 1. Execute frequency count
    INVOKE CountFrequency

    ; 2. Execute Huffman tree build
    INVOKE BuildHuffmanTree
    MOV EBX, EAX ; EBX stores the root node pointer (this is Personnel 2's final deliverable)

    ; 3. Display results (optional: for verification)
    ; V4 Fix: ADDR -> OFFSET
    MOV EDX, OFFSET msg_root
    INVOKE WriteString
    MOV EAX, (HuffNode PTR [EBX]).freq ; Root node frequency (should be 20)
    INVOKE WriteDec
    INVOKE Crlf

    ; Program End 
    INVOKE ExitProcess, 0 
main ENDP

END main
