
# директива .DATA отмечает начало сегмента данных.  В этом сегменте
# следует размещать ваши переменные памяти.

.data
    cmd_awk: .string "awk"
	first_arg_awk: .string "-f" 
# ключ -f говорит о том что данные беруться из файла

	second_arg_awk: .string "command.awk"
    third_arg_awk: .string "log.txt"
    args_awk: .long cmd_awk, first_arg_awk, second_arg_awk, third_arg_awk, 0

	#

    cmd_sort: .string "sort"
    first_arg_sort: .string "-nrk3"
    args_sort: .long cmd_sort, first_arg_sort, 0
	#

	cmd_head: .string "head"
	args_head: .long cmd_head, 0
    # массив файловых дескрипторов для pipe
    fds: .int 0, 0
	fds1: .int 0, 0
.text
.globl _start
_start:
        # вызов pipe(fds)
        pushl $fds
        call pipe
        # вызов fork()
		pushl $fds1
		call pipe
		#
        call fork
        # переход к коду дочернего процесса для cat,
        # если fork вернул 0
        cmpl $0, %eax
        je child_awk
        # вызов fork() в родительском процессе
        call fork
        # переход к коду дочернего процесса для wc,
        # если fork вернул 0
        cmpl $0, %eax
        je child_sort
		call fork
		cmpl $0, %eax
		je child_head
        # close(fd[0]) в родительском процессе
        movl $fds, %eax
        pushl 0(%eax)
        call close
        # close(fd[1]) в родительском процессе
        movl $fds, %eax
        pushl 4(%eax)
        call close
		movl $fds1, %eax
        pushl 0(%eax)
        call close
        # close(fd[1]) в родительском процессе
        movl $fds1, %eax
        pushl 4(%eax)
        call close
        # вызов wait(NULL) - для cat
        pushl $0
        call wait
        # еще один вызов wait(NULL) - для wc
        pushl $0
        call wait
		#
		pushl $0
		call wait
finish:
        # вызов exit(0)
        movl $1, %eax
        movl $0, %ebx
        int $0x80
# код дочернего процесса для cat
child_awk:
        # вызов dup2(fds[1],1)
        pushl $1
        movl $fds, %eax
        pushl 4(%eax)
        call dup2
        # вызов close(fds[0]), close(fds[1])
        movl $fds, %eax
        pushl 0(%eax)
        call close
        movl $fds, %eax
        pushl 4(%eax)
        call close
		movl $fds1, %eax
        pushl 0(%eax)
        call close
        movl $fds1, %eax
        pushl 4(%eax)
        call close
        # вызов execve(cmd_cat, args_cat)
        pushl $args_awk
        pushl $cmd_awk
        call execvp
        call finish
# код дочернего процесса для wc
child_sort:
        # вызов dup2(fds[0],0)
        pushl $0
        movl $fds, %eax
        pushl (%eax)
        call dup2
        # вызов close(fds[0]), close(fds[1])
        movl $fds, %eax
        pushl 0(%eax)
        call close
        movl $fds, %eax
        pushl 4(%eax)
        call close
		#
		pushl $1
        movl $fds1, %eax
        pushl 4(%eax)
        call dup2
		#
		movl $fds1, %eax
        pushl 0(%eax)
        call close
        movl $fds1, %eax
        pushl 4(%eax)
        call close
        # вызов execve(cmd_wc, args_wc)
        pushl $args_sort
        pushl $cmd_sort
        call execvp
        call finish
child_head:
		pushl $0
		movl $fds1, %eax
		pushl (%eax) 
		call dup2
		#
		movl $fds, %eax
        pushl 0(%eax)
        call close
        movl $fds, %eax
        pushl 4(%eax)
        call close
		movl $fds1, %eax
        pushl 0(%eax)
        call close
        movl $fds1, %eax
        pushl 4(%eax)
        call close
		#
		pushl $args_head
		pushl $cmd_head
		call execvp
		call finish
