# Squelch all warnings, they're harmless but ProGuard
# escalates them as errors.
-dontwarn sun.misc.Unsafe
-dontwarn javax.naming.Context
-dontwarn javax.naming.InitialContext
-dontwarn javax.naming.NamingException
-dontwarn javax.naming.NoInitialContextException
-dontwarn javax.servlet.ServletRequestListener
-dontwarn javax.servlet.http.Cookie
-dontwarn javax.servlet.http.HttpServletRequest
-dontwarn sun.security.x509.X509Key