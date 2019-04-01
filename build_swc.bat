echo off

SET javaDir=k:\DATA\RW\PROJECTS\_PROGRAMMING_\_PROJECTS_\_BUILD_\java\bin
SET sdkJarsDir=k:\DATA\RW\PROJECTS\_PROGRAMMING_\_PROJECTS_\_BUILD_\sdk\win64--Flex-4-16-1--AIR-28\lib
SET frameworksDir=k:\DATA\RW\PROJECTS\_PROGRAMMING_\_PROJECTS_\_BUILD_\sdk\win64--Flex-4-16-1--AIR-28\frameworks

%javaDir%\java -jar %sdkJarsDir%\compc.jar +flexlib %frameworksDir% -source-path .\src -load-config build_swc_config.xml

pause
