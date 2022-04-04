import com.GameInterface.Game.Character;
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.GameInterface.UtilsBase;
import com.Utils.Archive;
import com.Utils.ID32;
import com.Utils.LDBFormat;
import com.fox.DD.DeleteWindow;
import com.fox.DD.ItemResult;
import mx.utils.Delegate;
/**
* @author SecretFox
*/
class com.fox.DD.Main
{
	public var SignalOpenWindow:DistributedValue;
	public var m_SwfRoot:MovieClip;
	public var m_DeleteWindow:DeleteWindow;
	public var m_Config:Archive;
	public var m_Player:Character;
	public var m_Inventory:Inventory;
	public var addedItems:Array = [];
	public var deleteTimeout:Number;

	public static function main(swfRoot:MovieClip)
	{
		var mod:Main = new Main(swfRoot);
		swfRoot.onLoad = function(){mod.Load()};
		swfRoot.onUnload = function(){mod.Unload()};
		swfRoot.OnModuleActivated = function(cfg){mod.Activate(cfg)};
		swfRoot.OnModuleDeactivated = function(){return mod.Deactivate()};
	}
	
	public function Main(root)
	{
		m_SwfRoot = root;
		SignalOpenWindow = DistributedValue.Create("DD_Open");
	}
	
	public function Load():Void
	{
		m_Player = Character.GetClientCharacter();
		m_Inventory = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_BackpackContainer, m_Player.GetID().GetInstance()));

		SignalOpenWindow.SignalChanged.Connect(SlotOpenWindow, this);
		m_Inventory.SignalItemAdded.Connect(SlotItemAddedBuffer, this);
	}

	public function Unload():Void
	{
		SignalOpenWindow.SignalChanged.Disconnect(SlotOpenWindow, this);
		m_Inventory.SignalItemAdded.Disconnect(SlotItemAddedBuffer, this);
	}

	public function Activate(cfg:Archive):Void
	{
		// Prevents main character from transferring their configs to alts on their first run of the mod
		if ( cfg.FindEntry("Player") != m_Player.GetName())
		{
			cfg = new Archive();
			cfg.AddEntry("Player", m_Player.GetName());
		}
		m_Config = cfg;
		//UtilsBase.PrintChatText(cfg.toString());
		SlotOpenWindow(SignalOpenWindow);
	}

	public function Deactivate(cfg:Archive):Archive
	{
		return m_Config;
	}

	public function SlotOpenWindow(dv:DistributedValue):Void
	{
		if (dv.GetValue())
		{
			if (m_DeleteWindow)
			{
				return;
			}
			m_DeleteWindow = DeleteWindow(m_SwfRoot.attachMovie("DeleteWindow", "m_DeleteWindow", m_SwfRoot.getNextHighestDepth(), {_x:Stage.width / 2 - 100, _y:Stage.height / 2 - 150}));
			m_DeleteWindow._x = DistributedValueBase.GetDValue("DD_x");
			m_DeleteWindow._y = DistributedValueBase.GetDValue("DD_y");
			m_DeleteWindow.SetContent("DeleteContent");
			m_DeleteWindow.ShowFooter(false);
			m_DeleteWindow.ShowHelpButton(false);
			m_DeleteWindow.SetTitle("DD v1.0.0");
			m_DeleteWindow.ShowStroke(false);
			m_DeleteWindow.SetPadding(5);
			m_DeleteWindow.SetDraggable(true);
			m_DeleteWindow.ShowResizeButton(false);
			m_DeleteWindow.GetContent().LoadIcons();
			m_DeleteWindow.GetContent().config = m_Config;
			m_DeleteWindow.SignalClose.Connect(SlotCloseWindow, this);
			m_DeleteWindow.GetContent().SignalSave.Connect(SlotSave, this);
			m_DeleteWindow.SignalMoved.Connect(SlotMoved, this);
		}
		else
		{
			m_DeleteWindow.removeMovieClip();
			m_DeleteWindow = undefined;
		}
	}

	private function SlotMoved():Void
	{
		DistributedValueBase.SetDValue("DD_x", m_DeleteWindow._x);
		DistributedValueBase.SetDValue("DD_y", m_DeleteWindow._y);
	}

	/**
	* Updated settings sent from DeleteWindowContent
	*/
	private function SlotSave(cfg:Archive): Void
	{
		m_Config = cfg;
		if ( DistributedValueBase.GetDValue("DD_SafeMode"))
		{
			for (var i = 0 ; i < m_Inventory.GetMaxItems(); i++)
			{
				SlotItemAddedBuffer(m_Inventory.GetInventoryID(), i);
			}
		}
	}

	/**
	* Close Button pressed
	*/
	private function SlotCloseWindow(): Void
	{
		SignalOpenWindow.SetValue(false);
	}
	
	/**
	* Wildcard matching
	* (*) Matches zero or more characters
	* (?) Matches any single character
	* https://www.geeksforgeeks.org/wildcard-character-matching/ except all examples are incorrect/incomplete
	*/
	public function match(needle:String, haystack:String) : Boolean
	{
		if (needle.length == 0 && haystack.length == 0)
			return true;
		
		if (needle.length == 0)
			return false;
			
		if ( haystack.length == 0)
		{
			if ( needle.charAt(0) != "*") return false;
			return match(needle.substr(1), haystack);
		}
		
		if (needle.charAt(0) == '?' || needle.charAt(0) == haystack.charAt(0))
			return match(needle.substring(1), haystack.substring(1));
		
		if (needle.charAt(0) == '*')
			return match(needle.substring(1), haystack) || match(needle, haystack.substring(1));
		return false;
	}
	
	/**
	 * Checks item againt all custom filters
	 * @param name Items name in lowercase
	 * @param itemID InventoryItem.m_ACGItem.m_TemplateID0
	 * @return true if matches any of the custom filters
	 */
	private function CustomMatch(name:String, itemID:Number) : Boolean
	{
		var customList:Array = m_Config.FindEntryArray("Custom");
		for (var i in customList)
		{
			var customEntry:String = customList[i].toLowerCase();
			if (customEntry.charAt(0) == "#") continue;
			if (customEntry == name || 
				(Number(customEntry) == itemID && itemID))
			{
				return true;
			}
			if (customEntry.length > 5 &&
				(customEntry.indexOf("*") != -1 || customEntry.indexOf("?") != -1))
			{
				if (match(customEntry, name)) return true;
			}
		}
		return false;
	}
	
	
	/**
	 * @param name Items name
	 * @return true if item name contains localized "Energized" string
	 */
	private function IsEnergized(name:String): Boolean
	{
		switch (LDBFormat.GetCurrentLanguageCode())
		{
			case "en":
				return name.indexOf("Energized") == 0;
			case "de":
				return name.indexOf("Energetisiertes") == 0;
			case "fr":
				return name.indexOf("énergisé") >= 0;
		}
	}

	/**
	* @param name Items name
	* @return ItemResult Object
	* {distillate:true} = Distillate
	* {distillate:false} = Catalyst
	* {distillate:null} = Other item
	*/
	private function IsDistillate(item:InventoryItem)
	{
		var type = "";
		var distillate = false;
		switch (item.m_RealType)
		{
			case 30151: // Weapon distillate/catalyst
				return {distillate:item.m_XP > 0, type:"Weapon", energized:IsEnergized(item.m_Name)};
			case 30152: // Talisman distillate/catalyst
				return {distillate:item.m_XP > 0, type:"Talisman", energized:IsEnergized(item.m_Name)};
			case 30153: // Glyph distillate/catalyst
				return {distillate:item.m_XP > 0, type:"Glyph", energized:IsEnergized(item.m_Name)};
			case 30154: // Signet distillate/catalyst
				return {distillate:item.m_XP > 0, type:"Signet", energized:IsEnergized(item.m_Name)};
			default:
				return {distillate:null}
		}
	}
	
	/**
	* Items sometime cannot be deleted right after getting added
	*/
	private function SlotItemAddedBuffer(inventoryID:ID32, itemPos:Number): Void
	{
		var item:InventoryItem = m_Inventory.GetItemAt(itemPos);
		addedItems.push(itemPos);
		clearTimeout(deleteTimeout);
		deleteTimeout = setTimeout(Delegate.create(this, SlotItemAdded), 1000);
	}
	
	private function SlotItemAdded(): Void
	{
		for (var i in addedItems)
		{
			var item:InventoryItem = m_Inventory.GetItemAt(addedItems[i]);
			if ( !item  || !item.m_Deleteable ) continue;
			var result:ItemResult = IsDistillate(item);
			
			// Not distillate, check custom filters
			if ( result.distillate != true) // true = distillate, false = Catalyst, null = other items
			{
				if (CustomMatch(item.m_Name.toLowerCase(), item.m_ACGItem.m_TemplateID0))
				{
					if ( DistributedValueBase.GetDValue("DD_SafeMode"))
					{
						UtilsBase.PrintChatText("DD: " + item.m_Name + " Should be deleted");
					}
					else
					{
						m_Inventory.DeleteItem(item.m_InventoryPos);
					}
				}
			}
			// Distillates
			else if (m_Config.FindEntry(result.type + "Enabled"))
			{
				var amount:Number = m_Config.FindEntry(result.type + "XP", 0);
				if (!amount || // No config entry for treshold
					isNaN(Number(amount)) || // Treshold not a number 
					!item.m_XP || // item has no exp
					item.m_XP > amount || // item has more exp
					(result.energized && !m_Config.FindEntry(result.type + "Energized"))) // is energized and config is not set to delete
					continue;
				if ( DistributedValueBase.GetDValue("DD_SafeMode"))
				{
					UtilsBase.PrintChatText("DD: " + item.m_Name + " Should be deleted");
				}
				else
				{
					m_Inventory.DeleteItem(item.m_InventoryPos);
				}
			}
		}
		addedItems = [];
	}
}