require 'rubypython/rubypyapi/python'
require 'rubypython/rubypyapi/macros'
require 'rubypython/rubypyapi/ptor'
require 'rubypython/rubypyapi/rtop'
require 'ffi'

module RubyPyApi

  #This object is an opaque wrapper around the C PyObject* type used by the python
  #C API. This class <em>should not</em> be used by the end user. They should instead
  #make use of the RubyPyApi::RubyPyProxy class and its subclasses.
  class PyObject
    @@ref_dict = {}

    attr_reader :pointer

    def initialize(rObject)
      if rObject.kind_of? FFI::Pointer 
        @pointer = rObject
      else
        @pointer = RTOP.rtopObject rObject
      end
      @@ref_dict[object_id] = true
      ObjectSpace.define_finalizer(self, PyObject.make_finalizer(@pointer))
    end

    def rubify
      PTOR.ptorObject @pointer
    end

    def hasAttr(attrName)
      Python.PyObject_HasAttrString(@pointer, attrName) == 1
    end

    def getAttr(attrName)
      pyAttr = Python.PyObject_GetAttrString @pointer, attrName
      self.class.new pyAttr
    end

    def setAttr(attrName, rbPyAttr)
      Python.PyObject_SetAttrString(@pointer, attrName, rbPyAttr.pointer) != -1
    end

    def callObject(rbPyArgs)
      pyReturn = Python.PyObject_CallObject(@pointer, rbPyArgs.pointer)
      self.class.new pyReturn
    end

    def xDecref
      Macros.Py_XDECREF @pointer
      @pointer = FFI::Pointer::NULL
      @@ref_dict.delete object_id
    end

    def xIncref
      Macros.Py_XINCREF @pointer
    end

    def null?
      @pointer.null?
    end

    def cmp(other)
      Python.PyObject_Compare @pointer, other.pointer 
    end

    def functionOrMethod?
      isFunc = (Macros.PyObject_TypeCheck(@pointer, Python.PyFunction_Type.to_ptr) != 0)
      isMethod = (Macros.PyObject_TypeCheck(@pointer, Python.PyMethod_Type.to_ptr) != 0)
      isFunc or isMethod
    end

    def callable?
      Python.PyCallable_Check(@pointer) != 0
    end

    def self.makeTuple(rbObject)
      pTuple = nil

      if Macros.PyObject_TypeCheck(rbObject.pointer, Python.PyList_Type.to_ptr) != 0
        pTuple = Python.PySequence_Tuple(rbObject.pointer)
      elsif Macros.PyObject_TypeCheck(rbObject.pointer, Python.PyTuple_Type.to_ptr) != 0
        ptuple = rbObject.pointer
      else
        pTuple = Python.PyTuple_Pack(1, :pointer, rbObject.pointer)
      end

      self.new pTuple
    end

    def self.newList(*args)
      rbList = self.new Python.PyList_New args.length

      args.each_with_index do |el, i|
        Python.PyList_SetItem rbList.pointer, i, el.pointer
      end

      rbList
    end

    def self.convert(*args)
      args.map! do |arg|
        if(arg.instance_of? RubyPyApi::PyObject)
          arg
        elsif(arg.instance_of?(RubyPyApi::RubyPyProxy))
          if(arg.pObject.null?)
            raise NullPObjectError.new("Null pointer pointer.")
          else
            arg.pObject
          end
        else
          RubyPyApi::PyObject.new(arg)
        end
      end
    end

    def self.buildArgTuple(*args)
      pList = RubyPyApi::PyObject.newList(*args)
      RubyPyApi::PyObject.makeTuple(pList)
    end

    def self.make_finalizer(pointer)
      proc {|obj_id| Macros.Py_XDECREF pointer if @@ref_dict.has_key? obj_id}
    end
  end

end
