// CMatrix.i -- SWIG interface
%module ndlmatrix
%{
#define NDLSWIG
#define SWIG_FILE_WITH_INIT
#include <sstream>
#include "CMatrix.h"
%}

%rename(ndlmatrix) CMatrix;

%extend CMatrix 
{
  string __str__() 
  {
    stringstream sout;
    sout << *$self;
    return sout.str();
  }
}

%include "numpy.i"
%init %{
import_array();
%}

%apply (int DIM1, int DIM2, double* IN_ARRAY2){(int numRows, int numCols, double* inVals)};
%apply (double* IN_ARRAY2, int DIM1, int DIM2){(double* inVals, int numRows, int numCols)};
%apply (int* IN_ARRAY1, int DIM1){(int* indexVals, int numIndices)};
%apply (double* INPLACE_ARRAY1, int DIM1){(double* outVals, int numElements)};
%apply (double* INPLACE_FARRAY2, int DIM1, int DIM2){(double* outVals, int numRows, int numCols)};


%include "typemaps.i"


%include "std_vector.i"



namespace std {
   %template(vectori) vector<int>;
   %template(vectorui) vector<unsigned int>;
   %template(vectors) vector<string>;
   %template(vectord) vector<double>;
};

%include "std_string.i"
%include "exception.i"


%exception {
  try 
  {
    $action  
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
%include "CNdlInterfaces.h"
%include "CMatrix.h"

