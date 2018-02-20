package ui.screens.display.readings
{
	import flash.utils.Dictionary;
	
	import database.BgReading;
	import database.CommonSettings;
	import database.Database;
	import database.LocalSettings;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.ImageLoader;
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.data.ListCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.Canvas;
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.RenderTexture;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	import utils.BgGraphBuilder;
	import utils.Constants;
	import utils.TimeSpan;
	
	[ResourceBundle("globaltranslations")]

	public class ReadingsManagementList extends List 
	{
		/* Display Objects */
		private var urgentHighCanvas:Canvas;
		private var urgentHighTexture:RenderTexture;
		private var highCanvas:Canvas;
		private var highTexture:RenderTexture;
		private var inRangeCanvas:Canvas;
		private var inRangeTexture:RenderTexture;
		private var lowCanvas:Canvas;
		private var lowTexture:RenderTexture;
		private var urgentLowCanvas:Canvas;
		private var urgentLowTexture:RenderTexture;
		
		/* Objects */
		private var accessoriesList:Array = [];
		private var accessoryDictionary:Dictionary = new Dictionary( true );
		
		/* Properties */
		private var urgentLowThreshold:Number;
		private var lowThreshold:Number;
		private var highThreshold:Number;
		private var urgentHighThreshold:Number;
		private var lowColor:uint;
		private var inRangeColor:uint;
		private var highColor:uint;
		private var urgentHighColor:uint;
		private var urgentLowColor:uint;
		private var dateFormat:String;
		
		public function ReadingsManagementList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialContent();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			//Get user's glucose thresholds
			urgentLowThreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				urgentLowThreshold = Math.round(((BgReading.mgdlToMmol((urgentLowThreshold))) * 10)) / 10;
			
			lowThreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				lowThreshold = Math.round(((BgReading.mgdlToMmol((lowThreshold))) * 10)) / 10;
			
			highThreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK))
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				highThreshold = Math.round(((BgReading.mgdlToMmol((highThreshold))) * 10)) / 10;
				
			urgentHighThreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				urgentHighThreshold = Math.round(((BgReading.mgdlToMmol((urgentHighThreshold))) * 10)) / 10;
			
			//Get user's glucose colors
			urgentLowColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_LOW_COLOR));
			lowColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_LOW_COLOR));
			inRangeColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_IN_RANGE_COLOR));
			highColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_HIGH_COLOR));
			urgentHighColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_HIGH_COLOR));
			
			//Get user's date format (24H/12H)
			dateFormat = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
		}
		
		private function setupContent():void
		{
			//Temporary content to display pior to rendering the entire readings list (this is done to avoid Spike's UI from freezing will data processes);
			var standByLabel:Label = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('glucosemanagementscreen','stand_by'), HorizontalAlign.CENTER);
			standByLabel.width = width - 20;
			
			dataProvider = new ListCollection
			(
				[
					{ label: "", accessory: standByLabel }
				]
			);
			
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				return item;
			};
		}
		
		public function populateReadings():void
		{
			//Icons
			urgentHighCanvas = createReadingIcon(urgentHighColor);
			urgentHighTexture = new RenderTexture(urgentHighCanvas.width, urgentHighCanvas.height);
			urgentHighTexture.draw(urgentHighCanvas);
			
			highCanvas = createReadingIcon(highColor);
			highTexture = new RenderTexture(highCanvas.width, highCanvas.height);
			highTexture.draw(highCanvas);
			
			inRangeCanvas = createReadingIcon(inRangeColor);
			inRangeTexture = new RenderTexture(inRangeCanvas.width, inRangeCanvas.height);
			inRangeTexture.draw(inRangeCanvas);
			
			lowCanvas = createReadingIcon(lowColor);
			lowTexture = new RenderTexture(lowCanvas.width, lowCanvas.height);
			lowTexture.draw(lowCanvas);
			
			urgentLowCanvas = createReadingIcon(urgentLowColor);
			urgentLowTexture = new RenderTexture(urgentLowCanvas.width, urgentLowCanvas.height);
			urgentLowTexture.draw(urgentLowCanvas);
			
			// Data
			var dataList:Array = [];
			var readingsList:Array = ModelLocator.bgReadings;
			
			for(var i:int = readingsList.length - 1 ; i >= 0; i--)
			{
				//Glucose reading properties
				var reading:BgReading = readingsList[i];
				var glucoseValue:String = BgGraphBuilder.unitizedString(reading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
				var glucoseValueNumber:Number = Number(glucoseValue);
				var glucoseTime:Date = new Date(reading.timestamp);
				
				//Row label
				var timeFormatted:String;
				if (dateFormat.slice(0,2) == "24")
					timeFormatted = TimeSpan.formatHoursMinutes(glucoseTime.getHours(), glucoseTime.getMinutes(), TimeSpan.TIME_FORMAT_24H);
				else
					timeFormatted = TimeSpan.formatHoursMinutes(glucoseTime.getHours(), glucoseTime.getMinutes(), TimeSpan.TIME_FORMAT_12H);
				var label:String = timeFormatted + "  -  " + glucoseValue;
				
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_NSLOG, "true");
				
				//Row icon (changes color depending of value of glucose reading
				var icon:RenderTexture;
				if (glucoseValueNumber >= urgentHighThreshold)
					icon = urgentHighTexture;
				else if (glucoseValueNumber >= highThreshold)
					icon = highTexture;
				else if (glucoseValueNumber > lowThreshold && glucoseValueNumber < highThreshold)
					icon = inRangeTexture;
				else if (glucoseValueNumber <= lowThreshold && glucoseValueNumber > urgentLowThreshold)
					icon = lowTexture;
				else
					icon = urgentLowTexture;
				
				//Push row into list
				dataList.push({ icon: icon, label: label, bgReading: reading, id: i });
			}
			
			dataProvider = new ArrayCollection(dataList);
			
			//Define Item Renderer
			itemRendererFactory = function itemRendererFactory():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.iconSourceField = "icon";
				itemRenderer.iconLoaderFactory = function():ImageLoader
				{
					var loader:ImageLoader = new ImageLoader();
					return loader;
				}
				itemRenderer.iconOffsetX = 10;
				itemRenderer.labelField = "label";
				itemRenderer.accessoryFunction = function(item:Object):Button
				{
					var deleteButton:Button = accessoryDictionary[ item ];
					if(!deleteButton)
					{
						deleteButton = new Button();
						deleteButton.defaultIcon = new Image(MaterialDeepGreyAmberMobileThemeIcons.deleteForeverTexture);
						deleteButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
						deleteButton.pivotX = -5;
						deleteButton.addEventListener(Event.TRIGGERED, onDeleteReading);
						accessoryDictionary[ item ] = deleteButton;
					}
					return deleteButton;
				}
				
				return itemRenderer;
			}
		}
		
		private function createReadingIcon(readingColor:uint):Canvas
		{
			var icon:Canvas = new Canvas();
			icon.beginFill(readingColor);
			icon.drawCircle(8,8,8);
			icon.endFill();
			
			return icon;
		}
		
		/**
		 * Event Handlers
		 */
		private function onDeleteReading(e:Event):void
		{
			//Get list row properties
			var item:Object = ((e.currentTarget as Button).parent as DefaultListItemRenderer).data as Object;
			var bgReading:BgReading = item.bgReading as BgReading;
			var id:int = item.id;
			
			var alert:Alert = AlertManager.showActionAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('globaltranslations','cant_be_undone'),
				Number.NaN,
				[
					{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","no_uppercase")  },	
					{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","yes_uppercase"), triggered: deleteReading }	
				],
				HorizontalAlign.CENTER
			);
			alert.buttonGroupProperties.gap = 10;
			alert.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			
			function deleteReading(e:Event):void
			{
				//Delete reading from Spike, database and list
				ModelLocator.bgReadings.removeAt(id);
				Database.deleteBgReadingSynchronous(bgReading);
				dataProvider.removeItem(item);
			}
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			//Clear accessories
			if (accessoryDictionary != null)
			{
				for each (var deleteButton:Button in accessoryDictionary) 
				{
					deleteButton.removeEventListener(Event.TRIGGERED, onDeleteReading);
					deleteButton.dispose();
					deleteButton = null;
				}
			}

			//Clear icons
			if (urgentHighCanvas != null)
			{
				urgentHighCanvas.dispose();
				urgentHighCanvas = null;
			}
			
			if (urgentHighTexture != null)
			{
				urgentHighTexture.dispose();
				urgentHighTexture = null;
			}
			
			if (highCanvas != null)
			{
				highCanvas.dispose();
				highCanvas = null;
			}
			
			if (highTexture != null)
			{
				highTexture.dispose();
				highTexture = null;
			}
			
			if (inRangeCanvas != null)
			{
				inRangeCanvas.dispose();
				inRangeCanvas = null;
			}
			
			if (inRangeTexture != null)
			{
				inRangeTexture.dispose();
				inRangeTexture = null;
			}
			
			if (lowCanvas != null)
			{
				lowCanvas.dispose();
				lowCanvas = null;
			}
			
			if (lowTexture != null)
			{
				lowTexture.dispose();
				lowTexture = null;
			}
			
			if (urgentLowCanvas != null)
			{
				urgentLowCanvas.dispose();
				urgentLowCanvas = null;
			}
			
			if (urgentLowTexture != null)
			{
				urgentLowTexture.dispose();
				urgentLowTexture = null;
			}
			
			super.dispose();
		}
	}
}