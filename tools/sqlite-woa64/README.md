# Windows ARM64 SQLite JNI Shim

`sqliteJni.dll` is a temporary WOA64 release workaround for AndroidX
`sqlite-bundled-jvm`. AndroidX SQLite `2.6.2` through `2.7.0-alpha04` only
publish `natives/windows_x64/sqliteJni.dll`; the Windows ARM64 portable build
needs `natives/windows_arm64/sqliteJni.dll`.

The DLL is built from `sqlite_jni_shim.cpp` and statically links SQLite via
vcpkg `sqlite3:arm64-windows-static`. It is injected into the packaged
`sqlite-bundled-jvm` jar by the meta release workflow, keeping Animeko source
unchanged until AndroidX provides an upstream Windows ARM64 native artifact.

Local rebuild:

```powershell
C:\vcpkg\vcpkg.exe install sqlite3:arm64-windows-static
cmd /c "`"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat`" arm64 && cl /LD /EHsc /std:c++17 /MT /I`"%JAVA_HOME%\include`" /I`"%JAVA_HOME%\include\win32`" /IC:\vcpkg\installed\arm64-windows-static\include tools\sqlite-woa64\sqlite_jni_shim.cpp /link /OUT:tools\sqlite-woa64\sqliteJni.dll /LIBPATH:C:\vcpkg\installed\arm64-windows-static\lib sqlite3.lib"
```
