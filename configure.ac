#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.
AC_PREREQ([2.69])
AC_INIT([Graduation Project], [1.0], [iocoder@aol.com])
AC_CONFIG_SRCDIR([firmware/calc.c])
#AC_CONFIG_HEADERS([config.h])

# Initialize automake.
AM_INIT_AUTOMAKE(-Wno-portability)

# Checks for programs.
AC_PROG_CC
AC_PROG_MAKE_SET

# Checks for libraries.
AC_CHECK_LIB([SDL], [SDL_Init])

# Checks for header files.
AC_CHECK_HEADERS([mach/mach.h malloc.h memory.h stddef.h stdlib.h string.h strings.h sys/file.h sys/ioctl.h sys/param.h termios.h unistd.h values.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_TYPE_UID_T
AC_C_INLINE
AC_TYPE_OFF_T
AC_TYPE_SIZE_T
AC_CHECK_HEADER_STDBOOL

# Checks for library functions.
AC_FUNC_ALLOCA
AC_FUNC_MALLOC
AC_FUNC_REALLOC
AC_FUNC_STRTOD
AC_CHECK_FUNCS([atexit bzero floor memchr memmove memset modf pow select])
AC_CHECK_FUNCS([sqrt strchr strcspn strpbrk strrchr strspn strstr strtol])
AC_CHECK_FUNCS([strtoul])

# Config files.
AC_CONFIG_FILES([Makefile
                 logo/Makefile
                 firmware/Makefile
                 hardware/Makefile
                 mipsemu/Makefile
                 vhdsim/Makefile])

# Generate output files.
AC_OUTPUT
