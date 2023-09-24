#cython: language_level=3

"""
Functions in this module give python-space wrappers for cython functions
exposed in numpy/__init__.pxd, so they can be tested in test_cython.py
"""
cimport numpy as cnp
cnp.import_array()


def is_td64(obj):
    return cnp.is_timedelta64_object(obj)


def is_dt64(obj):
    return cnp.is_datetime64_object(obj)


def get_dt64_value(obj):
    return cnp.get_datetime64_value(obj)


def get_td64_value(obj):
    return cnp.get_timedelta64_value(obj)


def get_dt64_unit(obj):
    return cnp.get_datetime64_unit(obj)


def is_integer(obj):
    return isinstance(obj, (cnp.integer, int))


def get_datetime_iso_8601_strlen():
    return cnp.get_datetime_iso_8601_strlen(0, cnp.NPY_FR_ns)


def convert_datetime64_to_datetimestruct():
    cdef:
        cnp.npy_datetimestruct dts
        cnp.PyArray_DatetimeMetaData meta
        cnp.int64_t value = 1647374515260292
        # i.e. (time.time() * 10**6) at 2022-03-15 20:01:55.260292 UTC

    meta.base = cnp.NPY_FR_us
    meta.num = 1
    cnp.convert_datetime64_to_datetimestruct(&meta, value, &dts)
    return dts


def make_iso_8601_datetime(dt: "datetime"):
    cdef:
        cnp.npy_datetimestruct dts
        char result[36]  # 36 corresponds to NPY_FR_s passed below
        int local = 0
        int utc = 0
        int tzoffset = 0

    dts.year = dt.year
    dts.month = dt.month
    dts.day = dt.day
    dts.hour = dt.hour
    dts.min = dt.minute
    dts.sec = dt.second
    dts.us = dt.microsecond
    dts.ps = dts.as = 0

    cnp.make_iso_8601_datetime(
        &dts,
        result,
        sizeof(result),
        local,
        utc,
        cnp.NPY_FR_s,
        tzoffset,
        cnp.NPY_NO_CASTING,
    )
    return result


cdef cnp.NpyIter* npyiter_from_npyiter_obj(object it):
    # this function supports up to 3 iterator operands
    cdef:
        cnp.NpyIter* cit
        # cnp.PyArray_Descr* op_dtypes[5]
        cnp.npy_uint32 op_flags[3]
        cnp.PyArrayObject* ops[3]
        cnp.npy_uint32 flags = 0

    if it.has_index:
        flags |= cnp.NPY_ITER_C_INDEX
    if it.has_delayed_bufalloc:
        flags |= cnp.NPY_ITER_BUFFERED | cnp.NPY_ITER_DELAY_BUFALLOC
    if it.has_multi_index:
        flags |= cnp.NPY_ITER_MULTI_INDEX

    # one of READWRITE, READONLY and WRTIEONLY at the minimum must be specified for op_flags
    for i in range(it.nop):
        op_flags[i] = cnp.NPY_ITER_READONLY

    for i in range(it.nop):
        # op_dtypes[i] = cnp.PyArray_DESCR(it.operands[i])
        ops[i] = <cnp.PyArrayObject*>it.operands[i]

    cit = cnp.NpyIter_MultiNew(it.nop, &ops[0], flags, cnp.NPY_KEEPORDER,
                               cnp.NPY_NO_CASTING, &op_flags[0],
                               <cnp.PyArray_Descr**>NULL)
    return cit


def get_npyiter_size(it: "nditer"):
    cdef cnp.NpyIter* cit = npyiter_from_npyiter_obj(it)
    return cnp.NpyIter_GetIterSize(cit)


def get_npyiter_ndim(it: "nditer"):
    cdef cnp.NpyIter* cit = npyiter_from_npyiter_obj(it)
    return cnp.NpyIter_GetNDim(cit)


def get_npyiter_nop(it: "nditer"):
    cdef cnp.NpyIter* cit = npyiter_from_npyiter_obj(it)
    return cnp.NpyIter_GetNOp(cit)


def get_npyiter_operands(it: "nditer"):
    cdef cnp.NpyIter* cit = npyiter_from_npyiter_obj(it)
    arr = cnp.NpyIter_GetOperandArray(cit)
    return tuple([<cnp.ndarray>arr[i] for i in range(it.nop)])


def get_npyiter_itviews(it: "nditer"):
    cdef cnp.NpyIter* cit = npyiter_from_npyiter_obj(it)
    return tuple(
        [cnp.NpyIter_GetIterView(cit, i) for i in range(it.nop)]
    )


def get_npyiter_dtypes(it: "nditer"):
    cdef cnp.NpyIter* cit = npyiter_from_npyiter_obj(it)
    arr = cnp.NpyIter_GetDescrArray(cit)
    return tuple([<cnp.dtype>arr[i] for i in range(it.nop)])


def npyiter_has_delayed_bufalloc(it: "nditer"):
    cdef cnp.NpyIter* cit = npyiter_from_npyiter_obj(it)
    return cnp.NpyIter_HasDelayedBufAlloc(cit)


def npyiter_has_index(it: "nditer"):
    cdef cnp.NpyIter* cit = npyiter_from_npyiter_obj(it)
    return cnp.NpyIter_HasIndex(cit)


def npyiter_has_multi_index(it: "nditer"):
    cdef cnp.NpyIter* cit = npyiter_from_npyiter_obj(it)
    return cnp.NpyIter_HasMultiIndex(cit)


def npyiter_has_finished(it: "nditer"):
    cdef cnp.NpyIter* cit = npyiter_from_npyiter_obj(it)
    cnp.NpyIter_GotoIterIndex(cit, it.index)
    return not (cnp.NpyIter_GetIterIndex(cit) < cnp.NpyIter_GetIterSize(cit))
