module unitests.completness;

import system;

unittest
{
    static assert(is(typeof(new SharpObject()) == SharpObject));
    static assert(is(typeof(SharpObject.Equals(Object.init, Object.init)) == bool));
    static assert(is(typeof(SharpObject.init.Equals(Object.init)) == bool));
    static assert(is(typeof(SharpObject.init.GetHashCode()) == int));
    static assert(is(typeof(SharpObject.init.GetType()) == TypeInfo));
    static assert(is(typeof(SharpObject.ReferenceEquals(Object.init, Object.init)) == bool));
    static assert(is(typeof(SharpObject.init.ToString()) == wstring));

    static assert(is(typeof(new SharpException()) == SharpException));
    static assert(is(typeof(new SharpException("")) == SharpException));
    static assert(is(typeof(new SharpException("", new SharpException())) == SharpException));
    //static assert(is(typeof(new SharpException(SerializationInfo.init, StreamingContext.init)) == SharpException));
    static assert(is(typeof(SharpException.init.GetBaseException()) == Throwable));
    //static assert(is(typeof(SharpException.GetObjectData(SerializationInfo.init, StreamingContext.init))));
    static assert(is(typeof(SharpException.init.GetType()) == TypeInfo));
    static assert(is(typeof(SharpException.init.Equals(Object.init)) == bool));
    static assert(is(typeof(SharpException.init.GetHashCode()) == int));
    static assert(is(typeof(SharpException.init.ToString()) == wstring));
    //static assert(is(typeof(SharpException.init.Data) == IDictionary!(wstring, Object)));
    static assert(is(typeof(SharpException.init.HelpLink) == wstring));
    static assert(is(typeof(SharpException.init.HResult) == int));
    static assert(is(typeof(SharpException.init.InnerException) == Throwable));
    static assert(is(typeof(SharpException.init.Message) == wstring));
    static assert(is(typeof(SharpException.init.Source) == wstring));
    static assert(is(typeof(SharpException.init.StackTrace) == wstring));
    //static assert(is(typeof(SharpException.init.TargetSite) == MethodBase));

}