package ro.ciacob.desktop.ui {
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
	 * - Vector
	 * 	 Generated as a list, unless there is a matching selection handling method (see below).
	 * 	 The only items that will be rendered in the list are those representing supported
	 * 	 types, as described herein. There will not be nested lists, however, rather buttons
	 * 	 that open the sub-list in a new target - which you set via configuration directives
	 * 	 (as is the case with more tuning of the generated list, such as number of visible items, 
	 * 	 whether to allow selection, etcetera). If the vector being generated is writeable,
	 * 	 buttons for adding/removing/reordering the items will also be provided.
	 * 
	 * - Object
	 * 	 Generated as a form of two columns, having field names on the left and corresponding
	 * 	 controls on the right. The only fields that will be rendered in the form are those 
	 * 	 representing supported types, as described herein. There will not be nested forms,
	 * 	 however, rather buttons that open the sub-form in a new target - which you set via 
	 * 	 configuration directives (as is the case with more tuning of the generated form, such
	 * 	 as paddings, whether to use the object's being generated instance name as the form 
	 * 	 title, etcetera). If the object being generated is writeable, buttons for 
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
	 * Consequently, the vector will be generated as a drop-down list instead of a list,
	 * and the `myData_selection` function will be called each time the list is selected
	 * a new item; and will receive the data item corresponding to the selection. 
	 * 
	 * There is also some manoeuver space left:
	 * 	 1. change the type of the `selectedItem` argument to asterisk (`*`), to make the
	 * 	    resulting drop-down list editable - the string the user may input will be 
	 * 	    converted to the type of the elements in the vector, see conversions rules
	 * 	    below;
	 * 	 2. and/or change the type of the `selectedItem` argument to a Vector to allow for
	 *      multiple selection - the user will have to use CTRL/CMD to select more than one 
	 * 		item (see Note below).
	 * 	
	 * 	Note:
	 *  A good alternative to a multiple selection drop-down list is a list of checkboxes.
	 * 	An Object containing only properties of the Boolean type will be generated as such.  
	 * 
	 * CONVERSIONS RULES
	 * Should a user provided string need to be converted to one of the supported types,
	 * the folowing conversion rules apply:
	 * 
	 * String To...			Conversion Rule
	 * 
	 * Boolean				String "true", case insensitive will produce boolean value `true`;
	 * 						anything else will produce boolean value `false`.
	 * 
	 * String				No change.
	 * 
	 * Number				String is passed to the `parseInt()` method and NaN results are 
	 * 						forced to 0. Hexadecimal and octal values are properly converted
	 * 						if expressed properly: 0x[A-F0-9]{1,}i and #[A-F0-9]{1,} is 
	 * 						acceptable for hexadecimal; and 0[1-7]{1,} is acceptable for octal. 
	 * 
	 * Integer				Same as for Number, and the result will be cast to Integer,
	 * 						possibly loosing information. Make sure you use the proper type.
	 * 
	 * Unsigned Integer		Same as for Number, and the result will be cast to Unsigned Integer,
	 * 						possibly loosing information. Make sure you use the proper type.
	 * 
	 * Vector				An empty Vector of type String will be created, then the provided string
	 * 						will be added at index 0.
	 * 
	 * Object				An empty Object will be created, then the provided string will be used
	 * 						as both key and value of the one and only property to be added to that
	 * 						Object.
	 * 
	 * CONFIGURATION
	 * The class accepts a configurations object (of type IUIGeneratorConfiguration),
	 * which governs much of the generation process, such as providing a more 
	 * detailed label for the controls (instead of the de-camelized version of the
	 * class members), changing the order of the controls in page, etc. See the
	 * specific documentation for IUIGeneratorConfiguration.
	 * 
	 * @see IUIGeneratorConfiguration
	 * @see IUIGeneratorConfiguration.inputSource
	 */
	public interface IUIGenerator {
		
		/**
		 * An optional configuration object that governs the generation process.
		 * 
		 * Note:
		 * New configuration directives will only apply to upcoming generation tasks.
		 * Controls being generated and controls already generated will be unaffected. 
		 * 
		 * @param	value
		 * 			A new configuration object to apply. Optional, read
		 * 			IUIGeneratorConfiguration for details on default behavior.
		 * 
		 * @see IUIGeneratorConfiguration.
		 */
		function set configuration (value : IUIGeneratorConfiguration) : void;
		
		/**
		 * An optional configuration object that governs the generation process.
		 * 
		 * @param	value
		 * 			A new configuration object to apply. Optional, read
		 * 			IUIGeneratorConfiguration for details on default behavior.
		 * 
		 * @see IUIGeneratorConfiguration.
		 */
		function get configuration () : IUIGeneratorConfiguration;
		
		/**
		 * Begins the actual generation process (as generation is asynchronous).
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
		 * @param	callbackContext
		 * 			A context to execute the callback in. Optional, defaults to an
		 * 			empty, anonymous object.
		 */
		function generate(originator : Object, target : IUIComponent, callback : Function, callbackContext : Object = null) : void;
	}
}