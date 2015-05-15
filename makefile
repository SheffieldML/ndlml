
include make.inc

# dependencies created with gcc -MM XXX.cpp
all: _ndlml.so
	cd GPc; make

_ndlml.so: ml_wrap.o  CMatrix.o CGp.o CIvm.o CMltools.o COptimisable.o CNoise.o CKern.o CTransform.o CDist.o ndlfortran.o ndlstrutil.o ndlutil.o ndlassert.o
	g++ -shared ${XLINKERFLAGS} ml_wrap.o CMatrix.o CGp.o CIvm.o CMltools.o COptimisable.o CNoise.o CKern.o CTransform.o CDist.o ndlfortran.o ndlstrutil.o ndlutil.o ndlassert.o -o _ndlml.so $(LDFLAGS)

ml_wrap.cxx: ml.i CGp.h CMltools.h CIvm.h CNoise.h CKern.h CNdlInterfaces.h CTransform.h CDist.h CDataModel.h CMatrix.h
	swig -python -classic -c++ ml.i

ml_wrap.o: ml_wrap.cxx
	$(CC) -c ml_wrap.cxx -o ml_wrap.o $(CCFLAGS)


CIvm.o: CIvm.cpp CIvm.h CMltools.h ndlassert.h ndlexceptions.h \
  ndlstrutil.h COptimisable.h CMatrix.h CNdlInterfaces.h ndlutil.h \
  ndlfortran.h lapack.h CKern.h CTransform.h CDataModel.h CDist.h \
  CNoise.h
	$(CC) -c CIvm.cpp -o CIvm.o $(CCFLAGS)

CGp.o: CGp.cpp CGp.h CMltools.h ndlassert.h ndlexceptions.h ndlstrutil.h \
  COptimisable.h CMatrix.h CNdlInterfaces.h ndlutil.h ndlfortran.h \
  lapack.h CKern.h CTransform.h CDataModel.h CDist.h CNoise.h
	$(CC) -c CGp.cpp -o CGp.o $(CCFLAGS)

CNoise.o: CNoise.cpp CNoise.h ndlexceptions.h ndlutil.h ndlassert.h \
  ndlfortran.h ndlstrutil.h CMatrix.h CNdlInterfaces.h lapack.h \
  CTransform.h COptimisable.h CDist.h CKern.h CDataModel.h
	$(CC) -c CNoise.cpp -o CNoise.o $(CCFLAGS)

CMltools.o: CMltools.cpp CMltools.h ndlassert.h ndlexceptions.h \
  ndlstrutil.h COptimisable.h CMatrix.h CNdlInterfaces.h ndlutil.h \
  ndlfortran.h lapack.h CKern.h CTransform.h CDataModel.h CDist.h \
  CNoise.h
	$(CC) -c CMltools.cpp -o CMltools.o $(CCFLAGS)


CMatrix.o: CMatrix.cpp CMatrix.h ndlassert.h ndlexceptions.h \
  CNdlInterfaces.h ndlstrutil.h ndlutil.h ndlfortran.h lapack.h
	$(CC) -c CMatrix.cpp -o CMatrix.o $(CCFLAGS)

ndlassert.o: ndlassert.cpp ndlassert.h ndlexceptions.h
	$(CC) -c ndlassert.cpp -o ndlassert.o $(CCFLAGS)	

CKern.o: CKern.cpp CKern.h ndlassert.h ndlexceptions.h CTransform.h \
  CMatrix.h CNdlInterfaces.h ndlstrutil.h ndlutil.h ndlfortran.h lapack.h \
  CDataModel.h CDist.h
	$(CC) -c CKern.cpp -o CKern.o $(CCFLAGS)


CTransform.o: CTransform.cpp CTransform.h CMatrix.h ndlassert.h \
  ndlexceptions.h CNdlInterfaces.h ndlstrutil.h ndlutil.h ndlfortran.h \
  lapack.h
	$(CC) -c CTransform.cpp -o CTransform.o $(CCFLAGS)


COptimisable.o: COptimisable.cpp COptimisable.h CMatrix.h ndlassert.h \
  ndlexceptions.h CNdlInterfaces.h ndlstrutil.h ndlutil.h ndlfortran.h \
  lapack.h
	$(CC) -c COptimisable.cpp -o COptimisable.o $(CCFLAGS)

CDist.o: CDist.cpp CDist.h CMatrix.h ndlassert.h ndlexceptions.h \
  CNdlInterfaces.h ndlstrutil.h ndlutil.h ndlfortran.h lapack.h \
  CTransform.h
	$(CC) -c CDist.cpp -o CDist.o $(CCFLAGS)


ndlutil.o: ndlutil.cpp ndlutil.h ndlassert.h ndlexceptions.h ndlfortran.h
	$(CC) -c ndlutil.cpp -o ndlutil.o $(CCFLAGS)

ndlstrutil.o: ndlstrutil.cpp ndlstrutil.h ndlexceptions.h
	$(CC) -c ndlstrutil.cpp -o ndlstrutil.o $(CCFLAGS)


# Collected FORTRAN utilities.
ndlfortran.o: ndlfortran.f
	$(FC) -c ndlfortran.f -o ndlfortran.o $(FCFLAGS)


clean:
	rm *.o *_wrap.cxx

