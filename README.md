# ui-generator-library
Library that uses AS3 reflection to build a basic UI of components that bind back to reflected class' respective public fields. A number of supported custom annotations make the resulting UI more flexible.

Note that the compiler must be made aware that it must retain those custom annotations. This is achievable by adding the compiler argument:

-keep-as3-metadata+=Annotation1,Annotation2,AnnotationN

In Flash Builder, this will be added under "Properties"->"Flex Compiler"->"Additional compiler arguments".
