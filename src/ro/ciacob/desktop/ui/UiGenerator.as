package ro.ciacob.desktop.ui {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.EventDispatcher;
	import flash.utils.describeType;
	
	import ro.ciacob.desktop.ui.utils.CommonStrings;
	import ro.ciacob.desktop.ui.utils.Strings;
	

	/**
	 * Reference implementation for the IUIGenerator interface.
	 * @see IUIGenerator
	 */
	public class UiGenerator extends EventDispatcher implements IUiGenerator {

		/**
		 * @constructor
		 * @see IUIGenerator
		 * @see IUiBuilder
		 * 
		 * @param	builder
		 * 			Class definition of an IUiBuilder implementor to handle the actual building work. 
		 */
		public function UiGenerator (builder : Class) {
			_builderClass = builder;
		}

		private var _builderClass : Class;
		private var _builder : IUiBuilder;
		private var _queueCompletionCallback : Function;
		private var _externalChangeCallback : Function;
		private var _isGenerating : Boolean;
		private var _originator : Object;
		private var _uiMap:Object = {};
		private var _friendlyNamesMap : Object = {};
		private var _uiComponentBlueprints : Array = [];
		
		private static const READ_ACCESS : String = 'readonly';
		private static const READ_WRITE_ACCESS : String = 'readwrite';
		private static const SRC_SUFFIX : String = 'Src';
		private static const expectedMetadataNames : Array = [
			BlueprintKeys.INDEX,
			BlueprintKeys.DESCRIPTION,
			BlueprintKeys.MINIMUM,
			BlueprintKeys.MAXIMUM,
			BlueprintKeys.CUSTOM_COMPONENT
		];

		/**
		 * Returns the value of the `isGenerating` flag. Generating the UI is caried out in sessons, where each
		 * session must completely finish before another one can start.
		 * 
		 * The client code can both check for the `isGenerating` flag value and provide a "callback" argument 
		 * to the `generate()` function to cope with this limitation.
		 */
		public function get isGenerating () : Boolean {
			return _isGenerating;
		}
		
		/**
		 * Provides a faster alternative to <<container>>.getChildByName (<<accessorName>>) for retrieving an
		 * instance of a generated UI component. Each new generating session overrides the previous one, 
		 * therefore only the UI components generated in the latest session are available. Can return `null`
		 * if no such component exists.
		 */
		public function getComponentByName (name : String) : DisplayObject {
			return (_uiMap[name] as DisplayObject);
		}
		
		/**
		 * Starts the generating process, if not already running and sets the public flag "isGenerating" accordingly.
		 * if generation is already in progress, nothing happens.
		 * @seeIUIGenerator.generate
		 */
		public function generate (originator : Object, container : DisplayObjectContainer, onComplete : Function, onChange : Function = null) : void {
			if (!_isGenerating) {
				_isGenerating = true;
				_originator = originator;
				_queueCompletionCallback = onComplete;
				_externalChangeCallback = onChange;
				var typeInfo : XML = describeType (_originator);
				
				// If the originator is a simple Object, do a best effort guessing to produce
				// an acceptable list of blueprints for the components to be generated. This
				// situation is far from ideal, because information is scarce -- `describeType()`
				// does not work on simple Objects -- and binding is unavailable.
				if (typeInfo.@name == 'Object' || 
					(typeInfo.@base == 'Object' && typeInfo.@isDynamic == 'true')) {
					_uiComponentBlueprints = _inferBlueprints (_originator);
				}
				
				// If the originator is a custom class, all the needed information is
				// contained in the type description, and we only need to extract and
				// organize it.
				else {
					_uiComponentBlueprints = _extractBlueprints (typeInfo);
				}
				
				// Sort blueprints by index if given, or alphabetically by their labels (default)
				_uiComponentBlueprints.sort (_compareBlueprints);
				
				// Initialize given builder
				_builder = new _builderClass (_originator, container, _generateNext, _onUserChange);
				
				// Start building the components
				_uiMap = {};
				_builder.purgeContainer();		
				_generateNext();
			}
		}

		/**
		 * "Guesses" the UI components to be generated based on the enumerable
		 * properties  defined on a simple Object
		 */
		private function _inferBlueprints (originator : Object) : Array {
			var key : String;
			var value : Object;
			var type : String;
			var friendlyName : String;
			var bluePrint : Object;
			var matchingTargetName : String;
			var matchingSourceName : String;
			var additionalKey : String;
			var blueprints : Array = [];
			var additionalConfig : Object;
			
			for (key in originator) {
				
				// Filter out keys that start with a '$' sign
				if (key.charAt(0) != '$') {
				
					// Filter out properties inherited from the prototype chain
					if (originator.hasOwnProperty(key)) {
						value = originator[key];
						
						// Filter out unsupported types
						type = (value is int)? SupportedTypes.INT:
							(value is uint)? SupportedTypes.UINT:
							(value is Number)? SupportedTypes.NUMBER:
							(value is Boolean)? SupportedTypes.BOOLEAN:
							(value is String)? SupportedTypes.STRING:
							((value is Array) && value.constructor == Array)? SupportedTypes.ARRAY:
							((value is Object) && value.constructor == Object)? SupportedTypes.OBJECT:
							null;
						
						// Filter out "source" properties (properties which have no other purpose than to provide
						// the options to populate the selection lists with)
						if (type == SupportedTypes.ARRAY && Strings.endsWith (key, SRC_SUFFIX)) {
							matchingTargetName = key.slice(0, SRC_SUFFIX.length * -1);
							if (matchingTargetName in originator) {
								continue;
							}
						}
						
						// Filter out the configuration property
						if (key == BlueprintKeys.UI_GENERATOR_CONFIG) {
							continue;
						}
						
						// Construct a blueprint out of the data we gathered so far
						if (type != null) {
							bluePrint = {};
							bluePrint[BlueprintKeys.NAME] = key;
							friendlyName = Strings.capitalize(Strings.deCamelize (key));
							friendlyName = friendlyName.split (CommonStrings.UNDERSCORE).join (CommonStrings.SPACE);
							bluePrint[BlueprintKeys.LABEL] = friendlyName;
							bluePrint[BlueprintKeys.TYPE] = type;
							bluePrint[BlueprintKeys.DEFAULT] = value;
							
							// Grab the options to populate selection lists with; these are needed for accessors
							// of type Object or Array
							if (type == SupportedTypes.OBJECT || type == SupportedTypes.ARRAY) {
								matchingSourceName = key.concat(SRC_SUFFIX);
								if (matchingSourceName in originator) {
									bluePrint[BlueprintKeys.SOURCE] = originator[matchingSourceName];
								}
							}
							
							// Grab additional configuration if given
							if (BlueprintKeys.UI_GENERATOR_CONFIG in originator) {
								additionalConfig = originator[BlueprintKeys.UI_GENERATOR_CONFIG][key];
								for (additionalKey in additionalConfig) {
									if (expectedMetadataNames.indexOf(additionalKey) != -1) {
										bluePrint[additionalKey] = additionalConfig[additionalKey];
									}
								}
							}
							
							// Store the blueprint
							blueprints.push (bluePrint);
						}
					}
				}
			}
			
			
			return blueprints;
		}
		
		/**
		 * Digests the XML produced by "describeType()" in a concise Array of "blueprint"
		 * Objects, where each Object provides essential information for rendering one UI
		 * Component.
		 */
		private function _extractBlueprints (typeInfo : XML) : Array {
			var i : int;
			var j : int;
			var k : int;
			var L : int;
			var accessor : XML;
			var accessorName : String;
			var accessType : String;
			var friendlyName:String;
			var accessorType:String;
			var bluePrint : Object;
			var matchingSource : XML;
			var sourceAccessType : String;
			var sourceGetterName : String;
			
			var metadataNodes : XMLList;
			var numMetadataNodes : uint;
			var metadataNode : XML;
			var metadataName : String;
			
			var customComponentMetadata : Object;
			
			var argNodes : XMLList;
			var numArgNodes : uint;
			var argNode : XML;
			var argKey : String;
			var argValue : String;
			
			var description : String;
			var matchingSources:XMLList;
			var blueprints : Array = [];
			var typeLocalName : String = typeInfo.@name.toString();
			var accessors : XMLList = typeInfo..accessor.(@declaredBy == typeLocalName);
			var numAccessors : uint = accessors.length();
			for (i = 0; i < numAccessors; i++) {
				accessor = accessors[i] as XML;
				accessorName = accessor.@name.toString();
				if (accessorName.charAt(0) != '$') {
					accessType = accessor.@access.toString();
					if (accessType == READ_WRITE_ACCESS) {
						friendlyName = Strings.capitalize(Strings.deCamelize (accessorName));
						friendlyName = friendlyName.split (CommonStrings.UNDERSCORE).join (CommonStrings.SPACE);
						_friendlyNamesMap[accessorName] = friendlyName;
						accessorType = accessor.@type.toString();
						if (Strings.isAny (accessorType, 
							SupportedTypes.INT,
							SupportedTypes.UINT,
							SupportedTypes.NUMBER,
							SupportedTypes.BOOLEAN,
							SupportedTypes.STRING,
							SupportedTypes.ARRAY,
							SupportedTypes.OBJECT
						)) {
							bluePrint = {};
							bluePrint[BlueprintKeys.NAME] = accessorName;
							bluePrint[BlueprintKeys.LABEL] = friendlyName;
							bluePrint[BlueprintKeys.TYPE] = accessorType;
							bluePrint[BlueprintKeys.DEFAULT] = _originator[accessorName];
							
							// Grab the options to populate selection lists with; these are needed for accessors
							// of type Object or Array
							matchingSources = typeInfo..accessor.(@name == accessorName.concat(SRC_SUFFIX));
							if (matchingSources.length() > 0) {
								matchingSource = (matchingSources[0] as XML);
								sourceAccessType = matchingSource.@access.toString();
								if (sourceAccessType == READ_ACCESS) {
									sourceGetterName = matchingSource.@name.toString();
									bluePrint[BlueprintKeys.SOURCE] = (_originator[sourceGetterName] as Array);
								}
							}
							
							// Read the additional metadata if given
							metadataNodes = accessor.metadata;
							numMetadataNodes = metadataNodes.length();
							for (j = 0; j < numMetadataNodes; j++) {
								metadataNode = metadataNodes[j] as XML;
								metadataName = String (metadataNode.@name);
								if (expectedMetadataNames.indexOf(metadataName) == -1) {
									continue;
								}
								argNodes = metadataNode.arg;
								numArgNodes = argNodes.length();
								
								// The "CustomComponent" metadata accepts an arbitrary number
								// of arguments, therefore its value will be an Object
								// populated with the keys and values of all available
								// arguments
								if (metadataName == BlueprintKeys.CUSTOM_COMPONENT) {
									customComponentMetadata = {};
									for (L = 0; L < numArgNodes; L++) {
										argNode = argNodes[L] as XML;
										argKey = Strings.trim (argNode.@key);
										argValue = Strings.trim (argNode.@value);
										customComponentMetadata[argKey] = argValue;
									}
									bluePrint[metadataName] = customComponentMetadata;
								}
								
								// The rest of the supported metadata tags only expect
								// one argument named "value", therefore they will be
								// listed by their metadata tag name and the "value" of
								// their first argument
								else {
									if (numArgNodes != 0) {
										argNode =  argNodes[0] as XML;
										argValue = Strings.trim (argNode.@value);
										bluePrint[metadataName] = argValue;
									}
								}
							}
							blueprints.push (bluePrint);
						}
					}
				}
			}
			
			// If a description is given for an accessor, it can use the special syntax [accessorName]
			// to make a reference to another (related) accessor. Here we expand these references to 
			// the accessor's "friendly" name.
			for (k = 0; k < blueprints.length; k++) {
				bluePrint = blueprints[k];
				if (BlueprintKeys.DESCRIPTION in bluePrint) {
					description = (bluePrint[BlueprintKeys.DESCRIPTION] as String);
					description = _expandNames(description);
					bluePrint[BlueprintKeys.DESCRIPTION] = description;
				}
			}
			return blueprints;
		}
		
		/**
		 * Replaces '[myOtherAccessor]' with «My Other Accessor» within the given string.
		 *
		 * @param	text
		 * 			The text to search and replace in.
		 *
		 * @return	The text with changes applied, if any.
		 */
		private function _expandNames(text:String):String {
			if (!Strings.isEmpty(text)) {
				for (var name:String in _friendlyNamesMap) {
					var pSegm:Array = ['\\[', name, '\\]'];
					var pattern:RegExp = new RegExp(pSegm.join(''), 'g');
					var replacement:String = (['«', _friendlyNamesMap[name] as String, '»']).
						join('');
					text = text.replace(pattern, replacement);
				}
			}
			return text;
		}

		
		/**
		 *  Compares two blueprints based on their index
		 */
		private function _compareBlueprints (blueprintA : Object, blueprintB : Object) : int {
			var indexA : int = (parseInt (blueprintA[BlueprintKeys.INDEX]) as int);
			var indexB : int = (parseInt (blueprintB[BlueprintKeys.INDEX]) as int);
			var numericOrder : int = (indexA - indexB);
			if (!numericOrder) {
				var labelA : String = blueprintA[BlueprintKeys.LABEL] as String;
				var labelB : String = blueprintB[BlueprintKeys.LABEL] as String;
				return (labelA > labelB)? 1 : (labelA < labelB)? -1 : 0;
			}
			return numericOrder;
		}
		
		/**
		 * Causes the next UI Component in the queue to be generated.
		 */
		private function _generateNext() : void {
			var i : int = 0;
			var elBlueprint : Object = null;
			var key : String = null;
			if (_uiComponentBlueprints.length > 0) {
				elBlueprint = _uiComponentBlueprints.shift();
				key = elBlueprint[BlueprintKeys.NAME];
				var control : DisplayObject = _builder.buildUiElement (elBlueprint);
				
				// If a component was successfully built out of the current item
				// in the queue, register it and wait for it to render before moving on;
				// otherwise just skip to the next item in the queue.
				if (control != null) {
					_uiMap[key] = control;
				} else {
					_generateNext();
				}
			} else {
				_isGenerating = false;
				_queueCompletionCallback();
			}
		}

		/**
		 * Called when user changes current value inside a generated component. Causes the 
		 * corresponding originator class member's value to change accordingly. 
		 */
		private function _onUserChange(key:String, value:Object):void {
			_originator[key] = value;
			if (_externalChangeCallback != null) {
				_externalChangeCallback (key, value);
			}
		}
	}
}
