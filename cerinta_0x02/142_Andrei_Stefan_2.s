.data
    m: .space 4             # linii
    n: .space 4             # coloane
    n_bordat: .space 4      # coloane bordate
    p: .space 4             # nr de celule vii
    lineIndex: .space 4
    colIndex: .space 4
    matrix: .zero 1600
    cp_matrix: .zero 1600
    k: .space 4             # nr de evolutii
    x: .space 4
    y: .space 4
    cel_curenta: .space 4
    nr_vecini_vii: .space 4
    fp: .space 4            # file pointer
    filein: .asciz "in.txt"
    fileout: .asciz "out.txt"
    read_mode: .asciz "r"
    write_mode: .asciz "w"
    formatScanf: .asciz "%d"
    formatPrintf: .asciz "%d "
    endl: .asciz "\n"
.text
.global main
main:
    # deschidem fisierul de intrare
    push $read_mode
    push $filein
    call fopen
    addl $8,%esp
    movl %eax,fp

    # citim numarul de linii
    push $m
    push $formatScanf
    push fp
    call fscanf
    add $12,%esp

    # citim numarul de coloane
    push $n
    push $formatScanf
    push fp
    call fscanf
    add $12,%esp
    movl n,%eax
    addl $2,%eax
    movl %eax,n_bordat

    # citim numarul de celule vii
    push $p
    push $formatScanf
    push fp
    call fscanf
    add $12,%esp

    # citim celulele vii (matricea)
    xor %ecx,%ecx
    lea matrix,%edi

    for_p:
        cmp p,%ecx
        je exit_for_p

        push %ecx       # salvam valoarea lui ecx

        push $x         # citim x
        push $formatScanf
        push fp
        call fscanf
        add $12,%esp

        push $y         # citim y
        push $formatScanf
        push fp 
        call fscanf
        add $12,%esp

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
    push fp
    call fscanf
    addl $12,%esp

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
    # inchidem fisierul de intrare
    push fp
    call fclose 
    addl $4,%esp

    # deschidem fisierul de iesire
    push $write_mode
    push $fileout
    call fopen
    addl $8,%esp
    movl %eax,fp

    # afisam matricea
    movl $1,lineIndex
    lea matrix,%esi
    for_lines:
        movl lineIndex,%ecx
        cmp m,%ecx
        jg et_exit

        movl $1,colIndex
        for_columns:
            mov colIndex,%ecx
            cmp n,%ecx
            jg cont_for_lines
            
            # calculam pozitia in matrice

            mov lineIndex,%eax
            mull n_bordat
            addl colIndex,%eax

            # afisam elementul din matrice

            movl (%esi,%eax,4),%ebx
            push %ebx
            push $formatPrintf
            push fp
            call fprintf 
            addl $12,%esp

            incl colIndex
            jmp for_columns
    cont_for_lines:
        push $endl
        push fp
        call fprintf
        add $8,%esp
        incl lineIndex
        jmp for_lines


et_exit:
    # inchidem fisierul de iesire
    push fp
    call fclose
    addl $4,%esp

    pushl $0
    call fflush
    addl $4, %esp

    movl $1,%eax
    xor %ebx,%ebx
    int $0x80
