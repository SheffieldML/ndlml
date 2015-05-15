/* -*- C -*-  (not really, but good for syntax highlighting) */
// ml.i -- SWIG interface
%module ndlml
%{
#define NDLSWIG
#define SWIG_FILE_WITH_INIT
#include <sstream>
#include <numpy/arrayobject.h>
#include "CMatrix.h"
#include "CDist.h"
#include "CNoise.h"
#include "CKern.h"
#include "CMltools.h"
#include "CIvm.h"
#include "CGp.h"
%}

%include "numpy.i"

%init %{
import_array();
%}

// Need at least one apply directive to be included from numpy to get numpy.i functions included (used later)
%apply (double* IN_FARRAY2, int DIM1, int DIM2){(double* pythonInVals, int numRows, int numCols)};
// %apply (double* IN_ARRAY2, int DIM1, int DIM2){(double* inVals, int numRows, int numCols)};
// %apply (double* INPLACE_ARRAY1, int DIM1){(double* outVals, int numElements)};
// %apply (double* INPLACE_FARRAY2, int DIM1, int DIM2){(double* outVals, int numRows, int numCols)};


// // This type map makes an int[2] input into a tuple of two integers.
// %typemap(in) unsigned int[2] (unsigned int temp[2]) 
// { // temp[2] becomes a local variable
//   int i;
//   if(PyTuple_Check($input)) 
//   {
//     if(!PyArg_ParseTuple($input,"ii", temp, temp+1))
//     {
//       PyErr_SetString(PyExc_TypeError, "tuple of integers must have two elements.");
//       return NULL;
//     }
//     $1 = &temp[0];
//   } 
//   else
//   {
//     PyErr_SetString(PyExc_TypeError, "expected a tuple.");
//     return NULL;
//   }
// }
%extend CMatrix 
{
  PyObject* toarray() const
  {
    npy_intp dims[2];
    dims[0] = (npy_intp)$self->getRows();
    dims[1] = (npy_intp)$self->getCols();
    
    // TODO, should a reference count be increased here?
    PyArrayObject* array = (PyArrayObject *)PyArray_SimpleNew(2, dims, PyArray_DOUBLE);
    if(array==NULL)
    {	
      throw ndlexceptions::RuntimeError("toarray(): could not create python array.");
    }
    for(unsigned int i=0; i<$self->getRows(); i++) 
    {
      for(unsigned int j=0; j<$self->getCols(); j++) 
      {
	*(double *)(array->data + i*array->strides[0] + j*array->strides[1]) = $self->getVal(i, j);
      }
    }
    return PyArray_Return(array);
  }
  PyObject* tolist() const
  {
    PyObject* list = PyList_New($self->getRows());
    if(list==NULL)
    {	
      throw ndlexceptions::RuntimeError("tolist(): could not create python list.");
    }
    for(unsigned int i=0; i<$self->getRows(); i++) 
    {
      PyObject* curList =  PyList_New($self->getCols());
      PyList_SetItem(list, i, curList);   
      for(unsigned int j=0; j<$self->getCols(); j++) 
	PyList_SetItem(curList, j, Py_BuildValue("f", $self->getVal(i, j)));
    }
    return list;
  }
  CMatrix* fromarray(PyObject *input)
  {
    int convert = 0;
    PyArrayObject* array = obj_to_array_allow_conversion(input, PyArray_DOUBLE, &convert);
    cout << "Convert: " << convert << endl;
    $self->resize(array->dimensions[0], array->dimensions[1]);
    for(unsigned int i=0; i<$self->getRows(); i++) 
      for(unsigned int j=0; j<$self->getCols(); j++) 
	$self->setVal(*(double *)(array->data + i*array->strides[0] + j*array->strides[1]), i, j);
    return $self;
  }
// causes ipython attribute error when called in ipython shell
//   PyObject* __getattr__(std::string name)
//   {
//     PyObject* returnVal;
//     if(name=="shape")
//     {
//       returnVal = PyTuple_New(2);
//       if(returnVal == NULL)
//	 {
//         PyErr_SetString(PyExc_ValueError, "could not create tuple for attribute return.");
//	   return NULL;
//	 }
//       PyTuple_SetItem(returnVal, 0, Py_BuildValue("i", $self->getRows()));
//       PyTuple_SetItem(returnVal, 1, Py_BuildValue("i", $self->getCols()));
//     }
//     else
//     {
//         PyErr_SetString(PyExc_AttributeError, "unknown object attribute.");
//     } 
//     return returnVal;
//   }
  bool __eq__(CMatrix& other)
  {
    return $self->equals(other);
  }
  string __str__() 
  {
    stringstream sout;
    sout << *$self;
    return sout.str();
  }
  // Provides the ability to index the matrix in python.
  CMatrix* __getitem__(PyObject* ptuple) 
  {
    if(PyTuple_Check(ptuple)) 
    {
      Py_ssize_t length = PyTuple_Size(ptuple);
      if(length !=2) 
      {
	throw ndlexceptions::RuntimeError("__getitem__(): tuple incorrect length.");
      }
      PyObject* rowObject = PyTuple_GetItem(ptuple, 0);
      vector<unsigned int>* rowVec = getIndices(rowObject, $self->getRows());
      PyObject* colObject = PyTuple_GetItem(ptuple, 1);
      vector<unsigned int>* colVec = getIndices(colObject, $self->getRows());
      return new CMatrix(*$self, *rowVec, *colVec);
    }
    else
    {
      vector<unsigned int>* rowVec = getIndices(ptuple, $self->getRows()*$self->getCols());
      return new CMatrix(*$self, *rowVec);
    }
  }
}

%inline %{
  PyArrayObject* getCArrayFromPyObject(PyObject *input, int type, 
				       int minDim, int maxDim)
  {
    PyArrayObject *obj;
    if (PyArray_Check(input)) 
    {
      obj = (PyArrayObject *)input;
      if(!PyArray_ISCARRAY(obj)) 
      {
	throw ndlexceptions::TypeError("fromarray(): not a C array.");
      }
      obj = (PyArrayObject *)PyArray_FromObject(input, type, minDim, maxDim);
      if(obj == NULL) 
      {
	throw ndlexceptions::RuntimeError("fromarray(): could not run contiguousFromAny().");
      }
    }
    else 
    {
      throw ndlexceptions::TypeError("fromarray(): not an array.");
    }
    return obj;
  }
  vector<unsigned int>*  getIndices(PyObject* indObject, unsigned int length)
  {
    vector<unsigned int>* elements = new vector<unsigned int>();
    if(PySlice_Check(indObject))
    {
      Py_ssize_t *start0, *stop0, *step0, *slicelength0;
      if(PySlice_GetIndicesEx((PySliceObject*)indObject, length, start0, stop0, step0, slicelength0)!=0)
      {
	throw ndlexceptions::RuntimeError("getIndices(): unable to read slice.");
      }
      unsigned int i = 0;
      for(unsigned int i1=*start0; i<*stop0+1; i1+=*step0)
      {
	elements->push_back(i1);
	i++;
      }
    }
    else if(PyInt_Check(indObject))
    { 
      long input = PyInt_AsLong(indObject);
      if(input<0)
	input = length + input;
      if(input<0 || input>=length)
      {
	throw ndlexceptions::RuntimeError("getIndices(): index out of bounds.");
      }
      elements->push_back(input);
    }
    else if(PyList_Check(indObject))
    {
      unsigned int llength = PyList_Size(indObject);
      for(unsigned int i = 0; i<llength; i++)
      {
	PyObject* obj = PyList_GetItem(indObject, i);
	long input = 0;
	if(PyInt_Check(obj))	
	  input = PyInt_AsLong(obj); 	
	else
	{
	throw ndlexceptions::RuntimeError("getIndices(): list must contain integers.");
	}
	if(input<0)
	  input = length + input;
	if(input<0 || input>=length)
	{
	  throw ndlexceptions::RuntimeError("getIndices(): index out of bounds.");
	}
	elements->push_back(input);  
      }
    }
    else
    {
      throw ndlexceptions::RuntimeError("getIndices(): unknown index type.");
    }
    return elements; 
  }
%}

%extend CGp {
  bool __eq__(CGp& other)
  {
    return $self->equals(other);
  }

  string __str__() 
  {
    stringstream sout;
    $self->display(sout);
    return sout.str();
  }
}
%extend CIvm {
string __str__() {
  stringstream sout;
  $self->display(sout);
  return sout.str();
  }
}
%extend CKern {
string __str__() {
  stringstream sout;
  $self->display(sout);
  return sout.str();
  }
}
%extend CNoise {
string __str__() {
  stringstream sout;
  $self->display(sout);
  return sout.str();
  }
}

%include "typemaps.i"
%include "std_vector.i"
%include "std_string.i"

namespace std {
   %template(vectori) vector<int>;
   %template(vectorui) vector<unsigned int>;
   %template(vectors) vector<string>;
   %template(vectord) vector<double>;
   %template(vectorm) vector<CMatrix*>;
   %template(vectork) vector<CKern*>;
};




%feature("autodoc", "1");

%rename(ivm) CIvm;
%rename(gp) CGp;

%rename(gaussianDist) CGaussianDist;
%rename(gammaDist) CGammaDist;
%rename(wangDist) CWangDist;

%rename(mlpMapping) CMlpMapping;
%rename(linearMapping) CLinearMapping;
%rename(matrix) CMatrix;

%rename(ndlnoise) CNoise;
%rename(gaussianNoise) CGaussianNoise;
%rename(scaleNoise) CScaleNoise;
%rename(probitNoise) CProbitNoise;
%rename(ncnmNoise) CNcnmNoise;
%rename(orderedNoise) COrderedNoise;

%rename(kern) CKern;
%rename(cmpndKern) CCmpndKern;
%rename(tensorKern) CTensorKern;
%rename(whiteKern) CWhiteKern;
%rename(whitefixedKern) CWhitefixedKern;
%rename(biasKern) CBiasKern;
%rename(rbfKern) CRbfKern;
%rename(ratquadKern) CRatQuadKern;
%rename(matern32Kern) CMatern32Kern;
%rename(matern52Kern) CMatern52Kern;
%rename(linKern) CLinKern;
%rename(mlpKern) CMlpKern;
%rename(polyKern) CPolyKern;
%rename(linardKern) CLinardKern;
%rename(rbfardKern) CRbfardKern;
%rename(mlpardKern) CMlpardKern;
%rename(polyardKern) CPolyardKern;

%include "std_string.i"
%include "exception.i"

%exception {
  try 
  {
    $action  
  } 
  catch(ndlexceptions::RuntimeError& e)
  {
    PyErr_SetString(PyExc_RuntimeError, const_cast<char*>(e.what()));
  } 
  catch(ndlexceptions::FileError& e)
  {
    PyErr_SetString(PyExc_Exception, const_cast<char*>(e.what()));
  } 
  catch(ndlexceptions::MatrixError& e)
  {
    PyErr_SetString(PyExc_Exception, const_cast<char*>(e.what()));
  } 
  catch(ndlexceptions::Error& e)
  {
    PyErr_SetString(PyExc_Exception, const_cast<char*>(e.what()));
  } 
  catch(std::out_of_range& e) 
  {
    PyErr_SetString(PyExc_IndexError, const_cast<char*>(e.what()));
  } 
  catch(std::exception& e)
  {
    PyErr_SetString(PyExc_Exception, const_cast<char*>(e.what()));
  } 
  catch(...) 
  {
    PyErr_SetString(PyExc_Exception, "Unknown Exception");
  }	
}

// parse the original header file
//%nodefaultctor;
%include "CNdlInterfaces.h" 
%include "CMatrix.h"
%include "CTransform.h"
%include "CDataModel.h"
%include "COptimisable.h"
%include "CDist.h"
%include "CNoise.h"
%include "CKern.h"
%include "CMltools.h"
%include "CIvm.h"
%include "CGp.h"
