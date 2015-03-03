module system.runtime.serialization;

import system;

import internals.hresults;
import internals.resources;

@Serializable()
class SerializationException: SystemException
{
    this()
    {
        super(SharpResources.GetString("ExceptionSerialization"));
        HResult = COR_E_SERIALIZATION;
    }

    this(wstring msg)
    {
        super(msg);
        HResult = COR_E_SERIALIZATION;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        HResult = COR_E_SERIALIZATION;
    }
}