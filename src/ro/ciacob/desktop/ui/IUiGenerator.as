package ro.ciacob.desktop.ui {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * OVERVIEW
	 * ---------
	 * Inspects a given object (the `originator`) and generates UI controls which it 
	 * then adds as children to a given container (the `container`).
	 * 
	 * User interactions on the generated UI are automatically observed and 
	 * translated into value changes of the originator`s class members. Programmatic
	 * changes in the originator are also observed, and cause the generated controls
	 * to update their values. Editable controls will ignore these updates 
	 * while they are focused, and only accept user input.
	 * 
	 * SUPPORTED SCENARIOS
	 * The class will succeed in generating UI if:
	 * - The `originator` is a custom type, and it presents at least one getter/setter
	 *   pair (aka readwrite "accessor") of one of the supported types. List of choices
	 * 	 also require a third element, a getter (readonly accessor) named [SAME_NAME]Src.
	 * 
	 * - The `originator` is a simple Object, and it presents at least one property of
	 *   a supported type. Binding is not available with simple Objects, and source Arrays
	 *   must contain Object items in order to enable default selection in lists.
	 * 
	 * SUPPORTED TYPES
	 * Supported types are:
	 * - Boolean
	 * 	 Generated as a checkbox.
	 * 
	 * - String
	 * 	 Generated as an input text box.
	 * 
	 * - Number, Integer or Unsigned Integer
	 * 	 Generated as either a  numeric stepper or a slider, based on additional metadata.
	 * 	 Decimals will be accepted or not based on accessor type and additional metadata.
	 * 
	 * - Object
	 * 	 Generated as a single selection list; a readonly accessor named [SAME_NAME]Src
	 *   is required to provide the options for the list. 
	 * 
	 * - Array
	 * 	 Generated as a multiple selection list; a readonly accessor named [SAME_NAME]Src
	 *   is required to provide the options for the list. 
	 */
	public interface IUiGenerator {
		
		/**
		 * Returns the value of the `isGenerating` flag. Generating the UI is caried out in sessons, where each
		 * session must completely finish before another one can start.
		 * 
		 * The client code can both check for the `isGenerating` flag value and provide a "callback" argument 
		 * to the `generate()` function to cope with this limitation.
		 */
		function get isGenerating () : Boolean;
		
		/**
		 * Begins the actual generation process (generation is asynchronous).
		 * Invoking `generate()` while a generation task is in progress is
		 * ignored.
		 * 
		 * @param	originator
		 * 			An object or custom type to be mirrored via reflection methods
		 * 			and UI controls generated for it.
		 * 
		 * @param	container
		 * 			A container generated controls are to be added as children of.
		 * 
		 * @param	onComplete
		 * 			A function to be called when all controls have been generated
		 * 			and are ready to be used.
		 * 
		 * @param	onChange
		 * 			Optional. A function to be called when one of the generated components
		 * 			has changed value due to user interaction. Can be used as a trigger
		 * 			when binding is not available (e.g., when the `originator` is a simple
		 * 			Object). The expected function signature is:
		 * 
		 * 			function myFunction (key : String, value : Object) : void
		 * 
		 * 			`Key` is the accessor name that was changed and `value` is its new value.
		 * 			Originator's values are automatically changed when the user interacts with
		 * 			a generated component, so you don't need to. Use the `onChange` function
		 * 			if you want *something else* to also happen.
		 */
		function generate (originator : Object, container : DisplayObjectContainer, onComplete : Function, onChange : Function = null) : void;
		
		/**
		 * Provides a faster alternative to <<container>>.getChildByName (<<accessorName>>) for retrieving an
		 * instance of a generated UI component. Each new generating session overrides the previous one, 
		 * therefore only the UI components generated in the latest session are available. Can return `null`
		 * if no such component exists.
		 */
		function getComponentByName (name : String) : DisplayObject;
	}
}