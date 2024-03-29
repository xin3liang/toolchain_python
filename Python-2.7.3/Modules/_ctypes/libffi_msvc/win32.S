/* -----------------------------------------------------------------------
   win32.S - Copyright (c) 1996, 1998, 2001, 2002  Red Hat, Inc.
	     Copyright (c) 2001  John Beniton
	     Copyright (c) 2002  Ranjit Mathew


   X86 Foreign Function Interface

   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the
   ``Software''), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to
   the following conditions:

   The above copyright notice and this permission notice shall be included
   in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND, EXPRESS
   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
   IN NO EVENT SHALL CYGNUS SOLUTIONS BE LIABLE FOR ANY CLAIM, DAMAGES OR
   OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
   ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
   OTHER DEALINGS IN THE SOFTWARE.
   ----------------------------------------------------------------------- */

#define LIBFFI_ASM
#include <fficonfig.h>
#include <ffi.h>

.text

.globl ffi_prep_args

        # This assumes we are using gas.
        .balign 16
.globl _ffi_call_x86

_ffi_call_x86:
        pushl %ebp
        movl  %esp,%ebp

	#THe: save previous %esi, and store the current stack pointer in %esi
	pushl %esi
	movl %esp,%esi

        # Make room for all of the new args.
        movl  16(%ebp),%ecx
        subl  %ecx,%esp

        movl  %esp,%eax

        # Place all of the ffi_prep_args in position
        pushl 12(%ebp)
        pushl %eax
        call  *8(%ebp)

        # Return stack to previous state and call the function
        addl  $8,%esp

        # FIXME: Align the stack to a 128-bit boundary to avoid
        # potential performance hits.

	call  *28(%ebp)

	# Load ecif->cif->abi
#masm#	mov ecx, [ebp + 12]
        movl  12(%ebp),%ecx
#masm#	mov ecx, [ecx]ecif.cif
	movl  (%ecx),%ecx
#masm#	mov ecx, [ecx]ecif.cif.abi
	movl  (%ecx),%ecx
#masm#	cmp ecx, FFI_STDCALL
        cmpl  $2,%ecx
        je   noclean

	# STDCALL: Remove the space we pushed for the args
        movl  16(%ebp),%ecx
        addl  %ecx,%esp

	# CDECL: Caller has already cleaned the stack
noclean:
	# Check that esp has the same value as before!
	sub %esp,%esi # calculate stack pointer difference

        # Load %ecx with the return type code
        movl  20(%ebp),%ecx

        # If the return value pointer is NULL, assume no return value.
        cmpl  $0,24(%ebp)
        jne   retint

        # Even if there is no space for the return value, we are
        # obliged to handle floating-point values.
        cmpl  $FFI_TYPE_FLOAT,%ecx
        jne   noretval
        fstp  %st(0)

        jmp   epilogue

retint:
        cmpl  $FFI_TYPE_INT,%ecx
        jne   retfloat
        # Load %ecx with the pointer to storage for the return value
        movl  24(%ebp),%ecx
        movl  %eax,0(%ecx)
        jmp   epilogue

retfloat:
        cmpl  $FFI_TYPE_FLOAT,%ecx
        jne   retdouble
         # Load %ecx with the pointer to storage for the return value
        movl  24(%ebp),%ecx
        fstps (%ecx)
        jmp   epilogue

retdouble:
        cmpl  $FFI_TYPE_DOUBLE,%ecx
        jne   retlongdouble
        # Load %ecx with the pointer to storage for the return value
        movl  24(%ebp),%ecx
        fstpl (%ecx)
        jmp   epilogue

retlongdouble:
        cmpl  $FFI_TYPE_LONGDOUBLE,%ecx
        jne   retint64
        # Load %ecx with the pointer to storage for the return value
        movl  24(%ebp),%ecx
        fstpt (%ecx)
        jmp   epilogue

retint64:
        cmpl  $FFI_TYPE_SINT64,%ecx
        jne   retstruct
        # Load %ecx with the pointer to storage for the return value
        movl  24(%ebp),%ecx
        movl  %eax,0(%ecx)
        movl  %edx,4(%ecx)

retstruct:
        # Nothing to do!

noretval:
epilogue:
	movl %esi,%eax # return the stack pointer detlta in %eax
	popl %esi # restore previous %esi
        movl %ebp,%esp
        popl %ebp
        ret

.ffi_call_x86_end:
