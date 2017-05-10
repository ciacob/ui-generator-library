package ro.ciacob.desktop.ui {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.describeType;
	import mx.core.IUIComponent;
	import ro.ciacob.utils.Time;

	/**
	 * Reference implementation for the IUIGenerator interface.
	 * @see IUIGenerator
	 */
	public class UIGenerator extends EventDispatcher implements IUIGenerator {


		public function UIGenerator() {
		}

		private var _callback:Function;
		private var _callbackContext:Object;
		private var _config:IUIGeneratorConfiguration;
		private var _controlsLookupTable:Array;
		private var _generationDelay:int = Time.DEFAULT_DELAY_TIME;
		private var _isGenerating:Boolean;
		private var _originator:Object;
		private var _pendingConfig:IUIGeneratorConfiguration;
		private var _target:IUIComponent;
		private var _typeInfo:XML;

		public function get configuration():IUIGeneratorConfiguration {
			return _config;
		}

		public function set configuration(value:IUIGeneratorConfiguration):void {
			if (_isGenerating) {
				_pendingConfig = value;
			} else {
				_config = value;
				_applyConfiguration(_config);
			}
		}

		public function generate(originator:Object, target:IUIComponent, callback:Function, callbackContext:Object = null):void {
			if (!_isGenerating) {
				_originator = originator;
				_target = target;
				_callback = callback;
				if (callbackContext == null) {
					callbackContext = {};
				}
				_callbackContext = callbackContext;
				_typeInfo = describeType(originator);
				_controlsLookupTable = _extractControls(_typeInfo);
				_generateControls(_controlsLookupTable);
			}
		}

		private function _applyConfiguration(config:IUIGeneratorConfiguration):void {
		}

		private function _bindControl(control:IUIComponent):void {
		}

		private function _createControl(definition:Object, parent:DisplayObjectContainer):IUIComponent {
			return null;
		}

		private function _extractControls(typeInfo:XML):Array {
			return null;
		}

		private function _generateControls(lookupTable:Array):void {
			_isGenerating = true;
			_generateNext(lookupTable);
		}

		private function _generateNext(lookupTable:Array):void {
			if (lookupTable.length > 0) {
				var definition:Object = lookupTable.shift();
				var control:IUIComponent = _createControl(definition, DisplayObjectContainer(_target));
				_bindControl(control);
				Time.advancedDelay(_generateNext, this, _generationDelay, lookupTable);
			} else {
				_callback.apply(_callbackContext);
				_isGenerating = false;
				if (_pendingConfig != null) {
					_config = _pendingConfig;
					_pendingConfig = null;
					_applyConfiguration(_config);
				}
			}
		}
	}
}
