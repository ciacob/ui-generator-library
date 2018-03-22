package ro.ciacob.desktop.ui {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.describeType;
	
	import mx.controls.Label;
	import mx.controls.Spacer;
	import mx.core.ClassFactory;
	import mx.core.FlexGlobals;
	import mx.core.IContainer;
	import mx.core.IUIComponent;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.IStyleManager2;
	import mx.utils.ObjectUtil;
	
	import spark.components.CheckBox;
	import spark.components.ComboBox;
	
	import ro.ciacob.ui.flex.NonEditableNumericStepper;
	import ro.ciacob.ui.flex.PickupComponent;
	import ro.ciacob.utils.Strings;
	import ro.ciacob.utils.constants.CommonStrings;

	/**
	 * Reference implementation for the IUIGenerator interface.
	 * @see IUIGenerator
	 */
	public class UIGenerator extends EventDispatcher implements IUIGenerator {


		public function UIGenerator() {
		}

		private var _callback:Function;
		private var _controlsLookupTable:Array;
		private var _isGenerating:Boolean;
		private var _originator:Object;
		private var _target:IContainer;
		private var _typeInfo:XML;
		private var _labelsMap:Object = {};
		private var _uiMap:Object;
		private var _uiBindingsMap:Object;
		private var styleManager:IStyleManager2;
		
		// Component factories
		private var _checkBoxFactory:ClassFactory=new ClassFactory(CheckBox);
		private var _labelFactory:ClassFactory=new ClassFactory(Label);
		private var _numericStepperFactory:ClassFactory=new ClassFactory(NonEditableNumericStepper);
		private var _comboBoxFactory:ClassFactory=new ClassFactory(ComboBox);
		private var _pickupFactory:ClassFactory=new ClassFactory(PickupComponent);
		private var _spacerFactory:ClassFactory=new ClassFactory(Spacer);
		
		private static const READ_ACCESS:String = 'readonly';
		private static const READ_WRITE_ACCESS:String = 'readwrite';
		private static const SRC_SUFFIX:String = 'Src';
		private static const BOUND_EVENT:String='boundEvent';
		private static const BOUND_FUNCTION:String='boundFunction';

		public function get isGenerating () : Boolean {
			return _isGenerating;
		}
		
		public function generate(originator:Object, target:IContainer, callback:Function):Boolean {
			if (!_isGenerating) {
				_isGenerating = true;
				styleManager = ('styleManager' in _target)? _target['styleManager'] as IStyleManager2 : 
					(FlexGlobals.topLevelApplication && ('styleManager' in FlexGlobals.topLevelApplication))? 
						FlexGlobals.topLevelApplication['styleManager'] as IStyleManager2 :
							null;
					
				_originator = originator;
				_target = target;
				_callback = callback;
				_typeInfo = describeType(originator);
				_controlsLookupTable = _extractControls(_typeInfo);
				_generateControls();
				return true;
			}
			return false;
		}

		private function _bindControl(control:IUIComponent):void {
		}

		private function _extractControls(typeDescription:XML):Array {
			var ret:Array = [];
			var typeLocalName:String = typeDescription.@name.toString();
			var ownAccessors:XMLList = typeDescription..accessor.(@declaredBy == typeLocalName);
			for each (var accessor:XML in ownAccessors) {
				var aName:String = accessor.@name.toString();
				if (!Strings.beginsWith(aName, '$')) {
					var accessType:String = accessor.@access.toString();
					if (accessType == READ_WRITE_ACCESS) {
						var expandedName:String = Strings.properCase(Strings.deCamelize(aName));
						_labelsMap[aName] = expandedName;
						var type:String = accessor.@type.toString();
						if (Strings.isAny (type, 
							SupportedTypes.INT,
							SupportedTypes.NUMBER,
							SupportedTypes.BOOLEAN,
							SupportedTypes.STRING,
							SupportedTypes.ARRAY,
							SupportedTypes.OBJECT
						)) {
							var endPoint:Object = {};
							endPoint[EndPointKeys.NAME] = aName;
							endPoint[EndPointKeys.LABEL] = expandedName;
							endPoint[EndPointKeys.TYPE] = type;
							endPoint[EndPointKeys.DEFAULT] = this[aName];
							var matchingSources:XMLList = typeDescription..accessor.
								(@name == aName.concat(SRC_SUFFIX));
							if (matchingSources.length() > 0) {
								var srcNode:XML = (matchingSources[0] as XML);
								var srcAccessType:String = srcNode.@access.toString();
								if (srcAccessType == READ_ACCESS) {
									var srcGetterName:String = srcNode.@name.toString();
									endPoint[EndPointKeys.SOURCE] = (this[srcGetterName] as
										Array);
								}
							}
							var meta:XMLList = accessor.metadata;
							if (meta.length() > 0) {
								var expectedMetaNames:Array = [
									EndPointKeys.INDEX,
									EndPointKeys.DESCRIPTION,
									EndPointKeys.MINIMUM,
									EndPointKeys.MAXIMUM,
									EndPointKeys.ADVANCED,
									EndPointKeys.LIST_FONT_SIZE,
									EndPointKeys.EDITOR_FONT_SIZE,
									EndPointKeys.UNIQUE_SELECTION,
									EndPointKeys.DEPENDS_ON
								];
								for (var i:int = 0; i < expectedMetaNames.length; i++) {
									var nodeName:String = (expectedMetaNames[i] as String);
									var metaNode:XMLList = accessor.metadata.(@name == nodeName);
									if (metaNode.length() > 0) {
										var key:String = nodeName;
										var value:String = null;
										var args:XMLList = metaNode.arg;
										if (args.length() > 0) {
											value = Strings.trim((args[0] as XML).@value);
										}
										endPoint[key] = value;
									}
								}
							}
							ret.push(endPoint);
						}
					}
				}
			}
			for (var j:int = 0; j < ret.length; j++) {
				var el:Object = ret[j];
				if (EndPointKeys.DESCRIPTION in el) {
					var desc:String = (el[EndPointKeys.DESCRIPTION] as String);
					desc = _expandNames(desc);
					el[EndPointKeys.DESCRIPTION] = desc;
				}
			}
			return ret;
		}
		
		/**
		 * Replaces '[myEndPoint]' with 'My end point' within the given string.
		 *
		 * @param	text
		 * 			The text to search and replace in.
		 *
		 * @return	The text with changes applied, if any.
		 */
		private function _expandNames(text:String):String {
			if (!Strings.isEmpty(text)) {
				for (var name:String in _labelsMap) {
					var pSegm:Array = ['\\[', name, '\\]'];
					var pattern:RegExp = new RegExp(pSegm.join(''), 'g');
					var replacement:String = (['«', _labelsMap[name] as String, '»']).
						join('');
					text = text.replace(pattern, replacement);
				}
			}
			return text;
		}

		private function _compareElementsByIndex(elA:Object, elB:Object):int {
			var indexA:int=(parseInt(elA[EndPointKeys.INDEX]) as int);
			var indexB:int=(parseInt(elB[EndPointKeys.INDEX]) as int);
			return (indexA - indexB);
		}
		
		private function _generateControls():void {
			_uiMap={};
			_uiBindingsMap={};			
			_controlsLookupTable.sort(_compareElementsByIndex);
			_generateNext();
		}

		private function _generateNext():void {
			var i:int=0;
			var elBlueprint:Object=null;
			var key:String=null;
			if (_controlsLookupTable.length > 0) {
				elBlueprint = _controlsLookupTable.shift();
				key=elBlueprint[EndPointKeys.NAME];
				var control:IUIComponent = _buildUiElement(elBlueprint, _target);
				_uiMap[key]=control;
				control.addEventListener(FlexEvent.UPDATE_COMPLETE, _onGeneratedControlDrawn);
			} else {
				_callback.apply();
				_isGenerating = false;
			}
		}
		
		private function _onGeneratedControlDrawn (event : FlexEvent) : void {
			var target : IUIComponent = IUIComponent(event.target);
			target.removeEventListener(FlexEvent.UPDATE_COMPLETE, _onGeneratedControlDrawn);
			_generateNext();
		}
		
		private function _buildUiElement(blueprint:Object, container:IContainer):UIComponent {
			
			var name:String=(blueprint[EndPointKeys.NAME] as String);
			var type:String=(blueprint[EndPointKeys.TYPE] as String);
			var label:String=(blueprint[EndPointKeys.LABEL] as String);
			var description:String=Strings.trim(blueprint[EndPointKeys.DESCRIPTION] as String);
			
			// Base property set
			var baseProps:Object={};
			baseProps['percentWidth']=100;
			
			// Create a separate label for the component, unless it is a CheckBox
			if (type != SupportedTypes.BOOLEAN) {
				
				// Label base property set 
				var labelBaseProps:Object=ObjectUtil.clone(baseProps);
				delete labelBaseProps['uid'];
				labelBaseProps['truncateToFit']=true;
				
				// Current label property set
				var labelProps:Object=ObjectUtil.clone(labelBaseProps);
				delete labelProps['uid'];
				labelProps['text']=label.concat(CommonStrings.COLON_SPACE);
				if (!Strings.isEmpty(description)) {
					labelProps['toolTip']=description;
				}
				
				// Create a label for the control
				_labelFactory.properties=labelProps;
				container.addChild(_labelFactory.newInstance() as UIComponent);
			}
			
			// Create the actual component
			var component:UIComponent;
			var bindData:Object;
			var source:Array;
			switch (type) {
				
				// Draw a CheckBox for a Boolean accessor
				case SupportedTypes.BOOLEAN:
					var cbProps:Object=ObjectUtil.clone(baseProps);
					delete cbProps['uid'];
					cbProps['name']=name;
					cbProps['label']=label;
					cbProps['toolTip']=description;
					_checkBoxFactory.properties=cbProps;
					component=_checkBoxFactory.newInstance();
					component.addEventListener(Event.CHANGE, _onCbChange);
					bindData={};
					bindData[BOUND_EVENT]=Event.CHANGE;
					bindData[BOUND_FUNCTION]=_onCbChange;
					_uiBindingsMap[name]=bindData;
					break;
				
				// Draw a NumericStepper for a Number or int accessor
				case SupportedTypes.NUMBER:
				case SupportedTypes.INT:
					var stepperProps:Object=ObjectUtil.clone(baseProps);
					delete stepperProps['uid'];
					stepperProps['name']=name;
					var minimum:Number=parseFloat(blueprint[EndPointKeys.MINIMUM]);
					if (!isNaN(minimum)) {
						stepperProps['minimum']=minimum;
					}
					var maximum:Number=parseFloat(blueprint[EndPointKeys.MAXIMUM]);
					if (!isNaN(maximum)) {
						stepperProps['maximum']=maximum;
					}
					if (type == SupportedTypes.NUMBER) {
						stepperProps['stepSize']=0.05;
						var isPercentage:Boolean=(minimum >= 0 && maximum <= 1);
						if (isPercentage) {
							stepperProps['formattingFunction']=Strings.toPercentageFormat;
						}
					} else {
						stepperProps['stepSize']=1;
					}
					_numericStepperFactory.properties=stepperProps;
					component=_numericStepperFactory.newInstance();
					component.addEventListener(Event.CHANGE, _onNsChange);
					bindData={};
					bindData[BOUND_EVENT]=Event.CHANGE;
					bindData[BOUND_FUNCTION]=_onNsChange;
					_uiBindingsMap[name]=bindData;
					break;
				
				// Draw a PickupComponent for an Array accessor; its source is read from a [sameName]Src getter of type Array
				case SupportedTypes.ARRAY:
					var pickupProps:Object=ObjectUtil.clone(baseProps);
					delete pickupProps['uid'];
					pickupProps['name']=name;
					pickupProps['editorTitle']=label;
					var listFontSize:Number=parseInt(blueprint[EndPointKeys.LIST_FONT_SIZE]);
					if (!isNaN(listFontSize)) {
						var listStyle:CSSStyleDeclaration=new CSSStyleDeclaration;
						listStyle.setStyle('fontSize', listFontSize);
						var listStyleName:String=CommonStrings.DOT.concat(blueprint[EndPointKeys.NAME], CommonStrings.UNDERSCORE, EndPointKeys.LIST_FONT_SIZE);
						if (styleManager) {
							styleManager.setStyleDeclaration(listStyleName, listStyle, false);
						}
						pickupProps['itemStyleName']=listStyleName;
					}
					var editorFontSize:Number=parseInt(blueprint[EndPointKeys.EDITOR_FONT_SIZE]);
					if (!isNaN(editorFontSize)) {
						var editorStyle:CSSStyleDeclaration=new CSSStyleDeclaration;
						editorStyle.setStyle('fontSize', editorFontSize);
						var editorStyleName:String=CommonStrings.DOT.concat(blueprint[EndPointKeys.NAME], CommonStrings.UNDERSCORE, EndPointKeys.EDITOR_FONT_SIZE);
						if (styleManager) {
							styleManager.setStyleDeclaration(editorStyleName, editorStyle, false);
						}
						pickupProps['editorItemStyleName']=editorStyleName;
					}
					source=(blueprint[EndPointKeys.SOURCE] as Array);
					if (source != null) {
						pickupProps['availableItems']=source;
						source=null;
					}
					_pickupFactory.properties=pickupProps;
					component=_pickupFactory.newInstance();
					component.addEventListener(Event.CHANGE, _onPickUpChange);
					bindData={};
					bindData[BOUND_EVENT]=Event.CHANGE;
					bindData[BOUND_FUNCTION]=_onPickUpChange;
					_uiBindingsMap[name]=bindData;
					break;
				
				// An Object Accessor needs further refinement via metadata values
				case SupportedTypes.OBJECT:
					
					// Draw a BomboBox for an Object accessor that has a "UniqueSelection" metadata; its
					// choices are read from a [sameName]Src getter of type Array
					var hasUniqueSelection:Boolean=(EndPointKeys.UNIQUE_SELECTION in blueprint);
					if (hasUniqueSelection) {
						
						// Draw a ComboBox
						var comboProps:Object=ObjectUtil.clone(baseProps);
						delete comboProps['uid'];
						comboProps['name']=name;
						comboProps['labelField']='label';
						source=(blueprint[EndPointKeys.SOURCE] as Array);
						if (source != null) {
							comboProps['dataProvider']=source;
							source=null;
						}
						_comboBoxFactory.properties=comboProps;
						component=_comboBoxFactory.newInstance();
						component.addEventListener(Event.CHANGE, _onComboChange);
						bindData={};
						bindData[BOUND_EVENT]=Event.CHANGE;
						bindData[BOUND_FUNCTION]=_onComboChange;
						_uiBindingsMap[name]=bindData;
					}
					
					break;
			}
			
			// Add the generated component and return it
			if (component != null) {
				container.addChild(component);
				
				// Add a spacer after the component
				var spacerProps:Object={'height': 15};
				_spacerFactory.properties=spacerProps;
				var spacer:UIComponent=_spacerFactory.newInstance();
				container.addChild(spacer);
			}
			return component;
		}
		
		private function _onCbChange(event:Event):void {
			var cb:CheckBox=(event.target as CheckBox);
			var key:String=cb.name;
			var value:Boolean=cb.selected;
			_registerUserChange(key, value);
		}
		
		private function _onNsChange(event:Event):void {
			var ns:NonEditableNumericStepper=(event.target as NonEditableNumericStepper);
			var key:String=ns['name'];
			var value:Number=ns['value'];
			_registerUserChange(key, value);
		}
		
		private function _onPickUpChange(event:Event):void {
			var pickup:PickupComponent=(event.target as PickupComponent);
			var key:String=pickup['name'];
			var value:Array=pickup.pickedUpItems.concat();
			_registerUserChange(key, value);
		}
		
		private function _onComboChange(event:Event):void {
			var combo:ComboBox=(event.target as ComboBox);
			var key:String=combo.name;
			var value:Object=combo.selectedItem;
			_registerUserChange(key, value);
		}
		
		private function _registerUserChange(key:String, value:Object):void {
			_originator[key] = value;
		}
		
	}
}
