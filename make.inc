#
#  The machine (platform) identifier to append to the library names
#
SHELL = /bin/sh

PLAT = _UBUNTU
LAPACKDIR = /usr/lib/
LAPACKLIBS = ${LAPACKDIR}liblapack.so.3gf ${LAPACKDIR}libblas.so.3gf
F2CLIB = -lgfortran

# Uncomment these lines to set up the MATLAB interface.
#MATLABLIBS = -lmat -lmx
#MATLABBASE=/cygdrive/c/MATLAB701/
#MATLABRUNLIBDIR=${MATLABBASE}/bin/win32
#MATLABLIBDIR=${MATLABBASE}/extern/lib/win32/gcc
#MATLABINCLUDE=${MATLABBASE}/extern/include
#MATLABXLINKFLAG=-L${MATLABLIBDIR} -Xlinker -rpath -Xlinker ${MATLABRUNLIBDIR} 
#MATLABFLAG=-D_NDLMATLAB

PYTHONINCLUDE = /usr/include/python2.6/
PYTHONFLAG = -D_NDLPYTHON
INCLUDE = $(MATLABINCLUDE) $(PYTHONINCLUDE)

LD=g++
LDFLAGS=${MATLABLIBS} ${LAPACKLIBS} ${F2CLIB} -lc ${MATLABXLINKFLAG}
CC=g++
#CCFLAGS = -ggdb -DDBG -I$(INCLUDE) -D$(PLAT) $(MATLABFLAG) $(PYTHONFLAG)
CCFLAGS=-O2 -fPIC -I$(INCLUDE) -D$(PLAT) $(MATLABFLAG) $(PYTHONFLAG)
FC=gfortran
FCFLAGS=-O2 -fPIC

