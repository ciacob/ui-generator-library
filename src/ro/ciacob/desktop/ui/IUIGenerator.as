package ro.ciacob.desktop.ui {
	import mx.core.IContainer;
	import mx.core.IUIComponent;
	
	/**
	 * OVERVIEW
	 * Inspects a given object (the `originator`) and generates UI controls which it 
	 * then adds as children to a given container (`the target`).
	 * 
	 * User interactions on the generated UI are automatically observed and 
	 * translated into value changes of the originator`s class members. Programmatic
	 * changes in the originator are also observed, and cause the generated controls
	 * to update their values. By default, editable controls will ignore these updates 
	 * while they are focused, and only accept user input. This behavior is detailed in 
	 * the documentation for `IUIGeneratorConfiguration.inputSource`.
	 * 
	 * SUPPORTED SCENARIOS
	 * The class will succeed in generating UI if any of the following applies:
	 * - The `originator` is a simple Object, and it presents at least one function named
	 *   `setSomething(value : SupportedType)`, or `getSomething() : SupportedType`, or
	 * 	 both;
	 * 
	 * - The `originator` is a custom type, and it presents at least one getter or setter,
	 *   or both, of one of the supported types.
	 * 
	 * Getters alone will yeld read-only controls; matching getters and setters pairs will 
	 * yeld read-write controls; setters alone will create controls that accept user input
	 * and set appropriate values internally, but do not reflect programmatic changes to
	 * those values (passwords or other sensitive data are a good application for that).  
	 * 
	 * SUPPORTED TYPES
	 * Supported types are:
	 * - Boolean
	 * 	 Generated as a checkbox.
	 * 
	 * - String
	 * 	 Generated as an input text box.
	 * 
	 * - Number
	 * 	 Generated as a numeric stepper that accepts decimals and negative values. You set
	 * 	 the precision via configuration directives.
	 * 
	 * - Integer
	 * 	 Generated as a numeric stepper that does not accept decimals, but accepts negative
	 * 	 values.
	 * 
	 * - Unsigned Integer
	 * 	 Generated as a numeric stepper that accepts no decimals and no negative values.
	 * 
	 * - Vector (of supported types, excepting nested Vectors and Objects)
	 * 	 Generated as a list, unless there is a matching selection handling method (see below).
	 * 	 There will not be nested lists. If the vector being generated is writeable,
	 * 	 buttons for adding/removing/reordering the items will also be provided.
	 * 
	 * - Object
	 * 	 Generated as a form of two columns, having field names on the left and corresponding
	 * 	 controls on the right. The only fields that will be rendered in the form are those 
	 * 	 representing supported types, as described herein except for vectors and other Objects.
	 *   There will not be nested forms. If the object being generated is writeable, buttons for 
	 *   adding/removing/reordering the items will also be provided.
	 * 
	 * MATCHING SELECTION HANDLING METHOD
	 * Let's suppose the originator presents a read-only vector, "myData":
	 * 	 public function get myData () : Vector.<MySupportedType> { return _myData; }
	 * 
	 * If we also add a public method, "myData_selection":
	 * 	 public function myData_selection (selectedItem : MySupportedType) : void {}
	 * 
	 * then this method becomes the matching selection handling method for our vector.
	 * Consequently, the `myData_selection()` function will be called each time an item in
	 * the list is selected and receive the data item corresponding to the selection. 
	 * 
	 * There is also some manoeuver space left: set the type of the first argument of 
	 * `selectedItem()` to a Vector of supported types as described above, and multiple selection
	 * will be permitted - the user will have to use CTRL/CMD to select more than one 
	 * item (see Note below).
	 */
	public interface IUIGenerator {
		
		/**
		 * Begins the actual generation process (generation is asynchronous).
		 * Invoking `generate()` while a generation task is in progress is
		 * ignored.
		 * 
		 * @param	originator
		 * 			An object, or custom type to be mirrored via reflection methods,
		 * 			and UI controls generated accordingly.
		 * 
		 * @param	target
		 * 			A container generated controls are to be added as children to.
		 * 
		 * @param	callback
		 * 			A function to be called when all controls have been generated
		 * 			and are ready to be used by the user.
		 * 
		 * @return	Returns `true` if generation was successfully started. Returns
		 * 			`false` otherwise (commonly the case if generating is still in
		 * 			process);
		 */
		function generate(originator : Object, target : IContainer, callback : Function) : Boolean;
	}
}