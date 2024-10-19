.data
    m: .space 4                 # linii
    n: .space 4                 # coloane
    n_bordat: .space 4          # coloane bordate
    p: .space 4                 # nr de celule vii
    lineIndex: .space 4
    colIndex: .space 4
    matrixIndex: .space 4
    number_of_elements: .space 4  
    matrix: .zero 1600
    cp_matrix: .zero 1600
    k: .space 4                 # nr de evolutii
    CRIPT: .space 4
    x: .space 4
    y: .space 4
    cel_curenta: .space 4
    nr_vecini_vii: .space 4
    msg: .space 25
    msg_conv: .space 25         # mesaj criptat/decriptat
    formatScanf: .asciz "%d"
    formatStrScanf: .asciz "%s"
    formatPrintf: .asciz "%d "
    formatStrPrintf: .asciz "%s\n"
    endl: .asciz "\n"
.text

halfByte_to_hex:
    push %ebp
    movl %esp,%ebp

    movl 8(%ebp),%eax
    movl $10,%ecx
    cmp %ecx,%eax
    jl num
    jmp letter

    num:
        addl $48,%eax       # converteste in caracter ascii (numar 0-9)
        pop %ebp
        ret
    letter:
        addl $55,%eax       # converteste in caracter ascii (litera A-F)
        pop %ebp
        ret

hex_to_halfByte:
    push %ebp
    movl %esp,%ebp

    movl 8(%esp),%eax
    movl $65,%ecx
    cmp %ecx,%eax
    jge letter_sub
    jmp num_sub

    letter_sub:
        subl $55,%eax       # converteste un caracter A-F in binar
        pop %ebp
        ret
    num_sub:
        subl $48,%eax       # converteste un caracter 0-9 in binar
        pop %ebp
        ret

.global main
main:
    # citim numarul de linii
    push $m
    push $formatScanf
    call scanf
    add $8,%esp

    # citim numarul de coloane
    push $n
    push $formatScanf
    call scanf
    add $8,%esp
    movl n,%eax
    addl $2,%eax
    movl %eax,n_bordat

    # calculam numarul de elemente din matricea bordata

    movl m,%ebx
    addl $2,%ebx
    mull %ebx
    movl %eax,number_of_elements

    # citim numarul de celule vii
    push $p
    push $formatScanf
    call scanf
    add $8,%esp

    # citim celulele vii (matricea)
    xor %ecx,%ecx
    lea matrix,%edi

    for_p:
        cmp p,%ecx
        je exit_for_p

        push %ecx       # salvam valoarea lui ecx

        push $x         # citim x
        push $formatScanf
        call scanf
        add $8,%esp

        push $y         # citim y
        push $formatScanf
        call scanf
        add $8,%esp

        pop %ecx        # restauram valoarea lui ecx

        incl x          # matricea este bordata => coord++
        incl y

        movl x,%eax
        mull n_bordat
        addl y,%eax
        movl $1,(%edi,%eax,4)
        inc %ecx
        jmp for_p

exit_for_p:

    # citim k (numarul de evolutii)
    push $k
    push $formatScanf
    call scanf
    addl $8,%esp

    # citim CRIPT (CRIPT=1 - criptam | CRIPT=0 - decriptam)

    push $CRIPT
    push $formatScanf
    call scanf
    addl $8,%esp

    # citim mesajul

    push $msg
    push $formatStrScanf
    call scanf
    addl $8,%esp

    # calculam evolutiile
    lea matrix,%esi
    lea cp_matrix,%edi

    for_evolutii:
        cmpl $0,k
        je exit_for_evolutii

        movl $1,lineIndex

        for_lines_ev:
            movl lineIndex,%ecx
            cmp m,%ecx
            jg cont_for_evolutii

            movl $1,colIndex

            for_columns_ev:
                movl colIndex,%ecx
                cmp n,%ecx
                jg cont_for_lines_ev

                # calculam pozitia in matricea bordata
                mov lineIndex,%eax
                movl n_bordat,%ebx
                mull %ebx
                addl colIndex,%eax

                movl (%esi,%eax,4),%ebx
                movl %ebx,cel_curenta
                push %eax

                # calculam numarul de vecini vii
                movl $0,nr_vecini_vii

                subl n_bordat,%eax         # pozitia vecinului din stanga sus (scadem n+2+1)
                subl $1,%eax

                movl $3,%ecx
                for_linie_vecini:       # parcurgem blocul 3x3 din jurul elementului
                    push %ecx
                    movl $3,%ecx
                    for_vecini:
                        movl (%esi,%eax,4),%edx
                        addl nr_vecini_vii,%edx
                        movl %edx,nr_vecini_vii
                        
                        incl %eax
                        loop for_vecini

                    addl n,%eax         # eax+=n-1 - mergem pe urmatoarea linie din blocul 3x3
                    decl %eax

                    pop %ecx
                    loop for_linie_vecini

                movl nr_vecini_vii,%edx
                subl cel_curenta,%edx           # scadem celula curenta (celula nu este vecin pt ea insasi)
                movl %edx,nr_vecini_vii

                # Calculam valoarea celulei pt urmatoarea generatie
                # daca o celula are 3 vecini in viata => ea va fi in viata in generatia urmatoare (indiferent de starea actuala)
                # daca o celula *vie* are 2 vecini in viata => ramane in viata in generatia urmatoare
                # in orice alt caz celula va fi moarta in urmatoarea generatie
                
                # verificam daca are 3 vecini in viata
                pop %eax
                movl $0,(%edi,%eax,4)
                movl $3,%ebx
                cmp nr_vecini_vii,%ebx
                je cel_vie

                # verificam daca are 2 vecini in viata
                movl $2,%ebx
                cmp nr_vecini_vii,%ebx
                je check_if_alive
                jmp cel_moarta

                check_if_alive:
                    # verificam daca celula este in viata (si are 2 vecini)
                    cmpl $0,cel_curenta
                    je cel_moarta
                
                cel_vie:
                    movl $1,(%edi,%eax,4)

                cel_moarta:

                incl colIndex
                jmp for_columns_ev
                
        cont_for_lines_ev:
            incl lineIndex
            jmp for_lines_ev
    cont_for_evolutii:
        # mutam cp_matrix in matrix

        # calculam cate elemente trebuie sa parcurgem
        movl m,%eax
        movl n,%ebx
        addl $2,%eax
        addl $2,%ebx
        mull %ebx

        xor %ecx,%ecx
        for_elem:
            cmp %eax,%ecx
            je exit_for_elem

            # copiem in matrix elementele din cp_matrix
            movl (%edi,%ecx,4),%edx
            movl %edx,(%esi,%ecx,4)

            incl %ecx
            jmp for_elem

        exit_for_elem:
        decl k
        jmp for_evolutii

exit_for_evolutii:
    # decidem daca criptam sau decriptam
    cmpl $0,CRIPT
    je CRIPTARE
    jmp DECRIPTARE

CRIPTARE:
    # adaugam '0x' la inceput
    lea msg_conv,%edi
    xor %ecx,%ecx
    movb $48,(%edi,%ecx,1)      # '0'
    inc %ecx
    movb $120,(%edi,%ecx,1)     # 'x'

    # parcurgem mesajul ce trebuie criptat
    lea matrix,%esi
    xor %ecx,%ecx
    movl $0,matrixIndex
    while_msg:
        lea msg,%edi
        xor %ebx,%ebx
        movb (%edi,%ecx,1),%bl 
        cmpl $0,%ebx
        je exit_while_msg

        # extragem 8 biti din matrice in %eax (in %al)
        push %ecx
        push %ebx
        movl $8,%ecx
        xor %eax,%eax
        while_byte:
            xor %edx,%edx
            push %eax
            movl matrixIndex,%eax
            divl number_of_elements     # pozitia din matrice este in %edx (restul)
            pop %eax

            movl (%esi,%edx,4),%ebx     # extragem un element (=un bit) din matrice
            shl $1,%eax
            or %ebx,%eax            # adaugam bitul extras in eax

            incl matrixIndex
            loop while_byte

        pop %ebx

        xorb %al,%bl        # criptam litera (%bl) cu byte-ul extras din matrice (%al)
        movb %bl,%al
        
        shrb $4,%al
        push %eax
        call halfByte_to_hex    # convertim prima jumatate de byte intr-o litera hex (in ASCII)
        addl $4,%esp

        push %eax
        andb $0x0F,%bl
        push %ebx
        call halfByte_to_hex    # convertim a doua jumatate de byte intr-o litera hex (in ASCII)
        addl $4,%esp
        movl %eax,%ebx
        pop %eax

        # byte-ul criptat se afla sub forma ASCII in (%al,%bl) - 2 caractere hex
        lea msg_conv,%edi
        pop %ecx
        movl %ecx,%edx
        inc %edx        # in msg_conv avem aditional '0x'
        shl $1,%edx     # calculam edx*2
        movb %al,(%edi,%edx,1)
        incl %edx
        movb %bl,(%edi,%edx,1)

        inc %ecx
        jmp while_msg

exit_while_msg:
    # adaugam terminatorul nul sirului msg_conv
    lea msg_conv,%edi
    inc %ecx        # in msg_conv avem aditional '0x'
    shl $1,%ecx
    movb $0,(%edi,%ecx,1)

    # afisam sirul hexa
    push $msg_conv
    push $formatStrPrintf
    call printf 
    addl $8,%esp

    jmp et_exit

DECRIPTARE:
    lea matrix,%esi

    movl $0,matrixIndex
    movl $1,%ecx
    while_decript:
        lea msg,%edi
        xor %eax,%eax
        push %ecx
        shl $1,%ecx             # pargurgem msg 2 cate 2 caractere (cate 1 byte)
        movb (%edi,%ecx,1),%al
        cmpl $0,%eax
        je exit_while_decript

        # prima litera a fost extrasa in %al
        # extragem a doua litera din msg (pt a forma un byte complet)
        incl %ecx
        xor %ebx,%ebx
        movb (%edi,%ecx,1),%bl

        # convertim pe rand fiecare litera hexa in 4 biti

        push %eax
        call hex_to_halfByte        # covertim prima litera in 4 biti (%al)
        add $4,%esp

        push %eax
        push %ebx
        call hex_to_halfByte        # covertim a doua litera in 4 biti (%bl)
        addl $4,%esp
        movl %eax,%ebx
        pop %eax
        
        shl $4,%al
        or %al,%bl      # obtinem in %bl 1 byte din msg

        # extragem din matrice 1 byte in %eax (in %al)
        movl $8,%ecx
        xor %eax,%eax
        push %ebx
        while_byte_decript:
            xor %edx,%edx
            push %eax
            movl matrixIndex,%eax
            divl number_of_elements     # pozitia din matrice este in %edx (restul)
            pop %eax

            movl (%esi,%edx,4),%ebx     # extragem un element (=un bit) din matrice
            shl $1,%eax
            or %ebx,%eax            # adaugam bitul extras in eax

            incl matrixIndex
            loop while_byte_decript
        
        # decriptam byte-ul din msg (%bl) cu byte-ul din cheie (%al)
        pop %ebx
        xorb %bl,%al

        # byte-ul decriptat este codul ASCII al unui caracter
        lea msg_conv,%edi
        pop %ecx
        decl %ecx                   # -1 pt ca '0x' nu face parte din mesaj
        movb %al,(%edi,%ecx,1)
        incl %ecx

        incl %ecx
        jmp while_decript
exit_while_decript:
    # adaugam terminatorul nul
    lea msg_conv,%edi
    pop %ecx
    decl %ecx                   # -1 pt ca '0x' nu face parte din mesaj
    movb $0,(%edi,%ecx,1)

    # afisam mesajul
    push $msg_conv
    push $formatStrPrintf
    call printf
    addl $8,%esp

et_exit:
    push $0
    call fflush
    addl $4,%esp
	
    movl $1,%eax
    xor %ebx,%ebx
    int $0x80
