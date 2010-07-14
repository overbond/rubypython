require 'rubypython/rubypyapi/python'
require 'rubypython/rubypyapi/macros'

module RubyPyApi
  module PTOR

    def ptorString(pString)
      Python.PyString_AsString(pString)
    end

    def ptorList(pList)
      rb_array = []
      list_size = Python.PyList_Size(pList)
      
      list_size.times do |i|
	element = Python.PyList_GetItem(pList, i)
	Macros.rpPy_mXINCREF element
	rObject = ptorObject(element)
	rb_array.push rObject
      end

      rb_array
    end

    def ptorInt(pNum)
      Python.PyInt_AsLong pNum
    end

    def ptorLong(pNum)
      Python.PyLong_AsLong(pNum)
      #TODO Overflow Checking
    end

    def ptorFloat(pNum)
      Python.PyFloat_AsDouble(pNum)
    end

    def ptorTuple(pTuple)
      pList = Python.PySequence_List pTuple
      rArray = ptorList pList
      Macros.rpPy_mXDECREF pList
      rArray
    end

    def ptorDict(pDict)
      rb_hash = {}

      pos = FFI::MemoryPointer.new :int
      key = FFI::MemoryPointer.new :pointer
      val = FFI::MemoryPointer.new :pointer

      while Python.PyDict_Next(pDict, pos, key, val)
	pKey = key.read_pointer
	pVal = val.read_pointer
	rKey = ptorObject(pKey)
	rVal = ptorObject(pVal)
	rb_hash[rKey] = rVal
      end

      return rb_hash
    end

      
    def ptorObject(pObj)
      pointer = FFI::MemoryPointer.new :pointer
      rObj = nil

      pointer.write_pointer Python.PyString_Type
      if Macros.rpPyObject_mTypeCheck(pObj, pointer)
	rObj = ptorString pObj
      end

      pointer.write_pointer Python.PyList_Type
      if Macros.rpPyObject_mTypeCheck(pObj, pointer)
	rObj = ptorList pObj
      end

      pointer.write_pointer Python.PyInt_Type
      if Macros.rpPyObject_mTypeCheck(pObj, pointer)
	rObj = ptorInt pObj
      end

      pointer.write_pointer Python.PyLong_Type
      if Macros.rpPyObject_mTypeCheck(pObj, pointer)
	rObj = ptorLong pObj
      end

      pointer.write_pointer Python.PyFloat_Type
      if Macros.rpPyObject_mTypeCheck(pObj, pointer)
	rObj = ptorFloat pObj
      end

      pointer.write_pointer Python.PyTuple_Type
      if Macros.rpPyObject_mTypeCheck(pObj, pointer)
	rObj = ptorTuple pObj
      end

      pointer.write_pointer Python.PyDict_Type
      if Macros.rpPyObject_mTypeCheck(pObj, pointer)
	rObj = ptorDict pObj
      end

      if pObj == Macros.rpPy_mTrue
	rObj = true
      end

      if pObj == Macros.rpPy_mFalse
	rObj = false
      end

      if pObj == Macros.rpPy_mNone
	rObj = nil
      end

      rObj
    end

  end
end
