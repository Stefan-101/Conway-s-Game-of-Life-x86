# Aceasta versiune nu se foloseste de functii predefinite de citire/afisare

.data
    m: .space 4                 # linii
    n: .space 4                 # coloane
    n_bordat: .space 4          # coloane bordate
    p: .space 4                 # nr de celule vii
    lineIndex: .space 4
    colIndex: .space 4
    matrix: .zero 1600
    cp_matrix: .zero 1600
    k: .space 4                 # nr de evolutii
    x: .space 4
    y: .space 4
    cel_curenta: .space 4
    nr_vecini_vii: .space 4

    filein: .asciz "in.txt"
    fileout: .asciz "out.txt"
    fd: .space 4                # file descriptor
    endl: .asciz "\n"  
    buff: .zero 64              # buffer
.text

# Functia atoi_impl este o implementare a functiei atoi
atoi_impl:
    push %ebp
    movl %esp,%ebp
    push %edi
    push %ebx

    movl 8(%ebp),%edi
    xor %eax,%eax
    xor %ecx,%ecx

    et_while:
        xor %ebx,%ebx
        movb (%edi,%ecx,1),%bl   # verificare sfarsit sir
        cmp $0,%ebx
        je exit_while

        movl $'0',%edx        # verificare daca chr e cifra
        cmp %edx,%ebx
        jl exit_while
        movl $'9',%edx
        cmp %edx,%ebx
        jg exit_while

        subl $'0',%ebx        # transformam ebx in int si il adaugam
        movl $10,%edx
        mull %edx
        addl %ebx,%eax

        inc %ecx
        jmp et_while

exit_while:
    pop %ebx
    pop %edi
    pop %ebp
    ret

# Functia readf citeste intr-un buffer specificat o linie dintr-un fisier
# Parametrii: file_descriptor, buffer_address
readf:
    push %ebp
    movl %esp,%ebp
    push %ebx

    movl 8(%ebp),%ebx       # file descriptor
    movl 12(%ebp),%ecx      # buffer address
    
    while_not_eol:      # while not end of line
        # efectuam citirea unui byte din fisier folosind syscall in urmatoarea
        # locatie din buffer
        movl $3,%eax
        # ebx = fd
        # ecx = buff address
        movl $1,%edx
        int $0x80

        # verificam daca byte-ul citit este '\n' sau byte-ul '0' (EOF)
        movb 0(%ecx),%al
        incl %ecx
        movb $0x0A,%dl          # codificare pentru '\n'
        cmp %dl,%al
        je exit_while_not_eol
        cmp $0,%al              # byte-ul '0'
        je exit_while_not_eol
        jmp while_not_eol

    exit_while_not_eol:
    # adaugam terminatorul nul
    movb $0,0(%ecx)

    pop %ebx
    pop %ebp
    ret

# Functia writef scrie intr-un fisier o anumita lungime dintr-un buffer
# Parametrii: file_descriptor, buffer_address, length
writef:
    push %ebp
    movl %esp,%ebp
    push %ebx

    movl $4,%eax
    movl 8(%ebp),%ebx       # file descriptor
    movl 12(%ebp),%ecx      # buffer address
    movl 16(%ebp),%edx      # length
    int $0x80

    pop %ebx
    pop %ebp

    ret

# Functia cif_to_ascii primeste ca parametru 0 sau 1 (.long) si returneaza
# codul ascii pt 0 sau 1 respectiv
cif_to_ascii:
    push %ebp
    movl %esp,%ebp

    movl 8(%ebp),%eax
    addl $48,%eax

    pop %ebp
    ret
    
.global main
main:
    # deschidem fisierul pentru citire
    movl $5,%eax
    movl $filein, %ebx
    movl $0,%ecx        # read-only
    movl $0666,%edx     # permisiuni read-write pentru owner/grup/altii
    int $0x80

    movl %eax,fd        # salvam file descriptor

    # citim numarul de linii
    push $buff
    push fd
    call readf
    addl $8,%esp

    push $buff          # transformam in long numarul citit
    call atoi_impl
    addl $4,%esp
    movl %eax,m

    # citim numarul de coloane
    push $buff
    push fd
    call readf 
    addl $8,%esp

    push $buff          # transformam in long numarul citit
    call atoi_impl
    addl $4,%esp
    movl %eax,n

    addl $2,%eax
    movl %eax,n_bordat

    # citim numarul de celule vii
    push $buff
    push fd
    call readf 
    addl $8,%esp

    push $buff          # transformam in long numarul citit
    call atoi_impl
    addl $4,%esp
    movl %eax,p

    # citim celulele vii (matricea)
    xor %ecx,%ecx
    lea matrix,%edi

    for_p:
        cmp p,%ecx
        je exit_for_p

        push %ecx           # salvam valoarea lui ecx

        push $buff          # citim valoarea lui x
        push fd
        call readf 
        addl $8,%esp

        push $buff          # transformam valoarea lui x in long
        call atoi_impl
        addl $4,%esp
        movl %eax,x

        push $buff          # citim valoarea lui y
        push fd
        call readf 
        addl $8,%esp

        push $buff          # transformam valoarea lui y in long
        call atoi_impl
        addl $4,%esp
        movl %eax,y

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
    push $buff
    push fd
    call readf 
    addl $8,%esp

    push $buff          # transformam in long numarul citit
    call atoi_impl
    addl $4,%esp
    movl %eax,k

    # inchidem fisierul de intrare
    movl $6,%eax
    movl fd,%ebx
    int $0x80

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
    # deschidem fisierul de iesire
    movl $5,%eax
    movl $fileout, %ebx
    movl $0x241,%ecx     # 0x241 reprezinta flag-urile: O_CREAT, O_WRONLY si O_TRUNC
    movl $0666,%edx      # permisiuni read-write pentru owner/grup/altii
    int $0x80
    movl %eax,fd

    # afisam matricea
    movl $1,lineIndex
    lea matrix,%esi
    lea buff,%edi
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

            push %ebx               # transformam elementul in cod ASCII
            call cif_to_ascii
            addl $4,%esp

            movb %al,0(%edi)        # punem in buffer codul ASCII al elem si spatiu
            movb $0x20,1(%edi)

            push $2                 # afisam 2 bytes din buffer
            push $buff 
            push fd 
            call writef 
            addl $12,%esp

            incl colIndex
            jmp for_columns
    cont_for_lines:
        push $1                 # afisam '\n'
        push $endl 
        push fd 
        call writef 
        addl $12,%esp

        incl lineIndex
        jmp for_lines

et_exit:
    # inchidem fisierul
    movl $6,%eax
    movl fd,%ebx 
    int $0x80

    movl $1,%eax
    xor %ebx,%ebx
    int $0x80
